from datetime import date, datetime, timezone as dt_timezone
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APIClient, APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

from .models import DeviceToken, NotificationLog, UserNotificationPreferences

User = get_user_model()


def _client_for(user):
    client = APIClient()
    token = RefreshToken.for_user(user).access_token
    client.credentials(HTTP_AUTHORIZATION=f"Bearer {token}")
    return client


class NotificationPreferencesTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="tester", email="tester@heft.app", password="pass123"
        )
        self.client = _client_for(self.user)

    def test_get_creates_defaults(self):
        url = reverse("notification_preferences")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["all_enabled"])
        self.assertTrue(
            UserNotificationPreferences.objects.filter(user=self.user).exists()
        )

    def test_patch_updates_preferences(self):
        url = reverse("notification_preferences")
        response = self.client.patch(url, {"all_enabled": False}, format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data["all_enabled"])
        self.user.notification_preferences.refresh_from_db()
        self.assertFalse(self.user.notification_preferences.all_enabled)

    def test_patch_validates_workout_hour(self):
        url = reverse("notification_preferences")
        response = self.client.patch(url, {"workout_hour": 25}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_patch_validates_workout_days(self):
        url = reverse("notification_preferences")
        response = self.client.patch(url, {"workout_days": [8]}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_patch_validates_timezone(self):
        url = reverse("notification_preferences")
        response = self.client.patch(url, {"timezone": "Not/A/Zone"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        response = self.client.patch(
            url, {"timezone": "Europe/Madrid"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["timezone"], "Europe/Madrid")

    def test_unauthenticated_returns_401(self):
        self.client.credentials()
        url = reverse("notification_preferences")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)


class DeviceTokenTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="tokenuser", email="token@heft.app", password="pass123"
        )
        self.client = _client_for(self.user)

    def test_register_new_token(self):
        url = reverse("notification_devices")
        response = self.client.post(
            url,
            {"token": "fcm-abc-123", "platform": "android"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(DeviceToken.objects.filter(token="fcm-abc-123").exists())

    def test_register_same_token_updates_not_duplicates(self):
        url = reverse("notification_devices")
        self.client.post(url, {"token": "fcm-dup", "platform": "android"}, format="json")
        self.client.post(url, {"token": "fcm-dup", "platform": "android"}, format="json")
        self.assertEqual(DeviceToken.objects.filter(token="fcm-dup").count(), 1)

    def test_register_missing_fields_returns_400(self):
        url = reverse("notification_devices")
        response = self.client.post(url, {"token": "only-token"}, format="json")
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_delete_token_deactivates(self):
        token_obj = DeviceToken.objects.create(
            user=self.user, token="del-token", platform="ios"
        )
        url = reverse("notification_device_destroy", kwargs={"pk": token_obj.pk})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        token_obj.refresh_from_db()
        self.assertFalse(token_obj.is_active)

    def test_delete_other_user_token_returns_404(self):
        other = User.objects.create_user(
            username="other", email="other@heft.app", password="pass"
        )
        token_obj = DeviceToken.objects.create(
            user=other, token="other-token", platform="android"
        )
        url = reverse("notification_device_destroy", kwargs={"pk": token_obj.pk})
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_list_returns_active_tokens(self):
        DeviceToken.objects.create(user=self.user, token="t1", platform="android")
        DeviceToken.objects.create(user=self.user, token="t2", platform="ios", is_active=False)
        url = reverse("notification_devices")
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)


class NotificationLogTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="loguser", email="log@heft.app", password="pass123"
        )

    def test_log_creation(self):
        log = NotificationLog.objects.create(
            user=self.user,
            notification_type="workout_reminder",
            status="sent",
            title="Hora de entrenar",
            body="Sesión de hoy",
            dedup_key="2026-06-02",
        )
        self.assertEqual(str(log), "Log(loguser, workout_reminder, sent)")

    def test_dedup_key_prevents_duplicate_sent(self):
        NotificationLog.objects.create(
            user=self.user,
            notification_type="inactivity",
            status="sent",
            dedup_key="2026-06-02",
        )
        exists = NotificationLog.objects.filter(
            user=self.user,
            notification_type="inactivity",
            dedup_key="2026-06-02",
            status="sent",
        ).exists()
        self.assertTrue(exists)


@override_settings(CRON_SECRET="test-cron-secret", NOTIFICATIONS_ENABLED=True)
class CronNotificationsTests(APITestCase):
    def setUp(self):
        self.url = reverse("cron_notifications")
        self.client = APIClient()

    def test_requires_secret(self):
        response = self.client.post(self.url)
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    @patch("apps.notifications.cron.send_workout_reminders", return_value=1)
    @patch("apps.notifications.cron.send_body_progress_reminders", return_value=0)
    @patch("apps.notifications.cron.send_weekly_summaries", return_value=0)
    @patch("apps.notifications.cron.send_inactivity_alerts", return_value=0)
    def test_post_with_bearer_runs_jobs(self, *_mocks):
        response = self.client.post(
            self.url,
            HTTP_AUTHORIZATION="Bearer test-cron-secret",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data["ok"])
        self.assertEqual(response.data["results"]["workout_reminder"], 1)

    @override_settings(CRON_SECRET="")
    def test_missing_server_secret_returns_503(self):
        response = self.client.post(
            self.url,
            HTTP_AUTHORIZATION="Bearer anything",
        )
        self.assertEqual(response.status_code, status.HTTP_503_SERVICE_UNAVAILABLE)


class TimezoneAwareReminderTests(APITestCase):
    """Recordatorios según hora local del usuario (no UTC del servidor)."""

    def setUp(self):
        self.user = User.objects.create_user(
            username="tzuser", email="tz@heft.app", password="pass123"
        )
        self.prefs = UserNotificationPreferences.objects.create(
            user=self.user,
            timezone="Europe/Madrid",
            workout_enabled=True,
            workout_hour=9,
            workout_minute=0,
            workout_days=[0, 1, 2, 3, 4, 5, 6],
        )
        DeviceToken.objects.create(
            user=self.user, token="tok-tz", platform="android"
        )

    def _freeze_utc(self, year, month, day, hour, minute=0):
        aware = datetime(year, month, day, hour, minute, tzinfo=dt_timezone.utc)
        return patch("django.utils.timezone.now", return_value=aware)

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_workout_reminder_at_local_hour(self, _mock_push):
        from apps.notifications.tasks import send_workout_reminders

        # 08:00 UTC = 09:00 Europe/Madrid (invierno CET)
        with self._freeze_utc(2026, 1, 15, 8, 0):
            count = send_workout_reminders()
        self.assertEqual(count, 1)

        with self._freeze_utc(2026, 1, 15, 7, 0):
            count = send_workout_reminders()
        self.assertEqual(count, 0)

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_inactivity_only_at_local_10(self, _mock_push):
        from apps.notifications.tasks import send_inactivity_alerts

        self.prefs.inactivity_enabled = True
        self.prefs.inactivity_threshold_days = 3
        self.prefs.save()

        # 09:00 UTC = 10:00 Madrid
        with self._freeze_utc(2026, 1, 15, 9, 0):
            count = send_inactivity_alerts()
        self.assertEqual(count, 1)

        with self._freeze_utc(2026, 1, 15, 8, 0):
            count = send_inactivity_alerts()
        self.assertEqual(count, 0)

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_inactivity_message_uses_actual_days(self, mock_push):
        from apps.workouts.models import WorkoutSession
        from apps.notifications.tasks import send_inactivity_alerts

        self.prefs.inactivity_enabled = True
        self.prefs.inactivity_threshold_days = 4
        self.prefs.save()

        session = WorkoutSession.objects.create(
            user=self.user,
            is_completed=True,
        )
        # date tiene auto_now_add: hay que actualizarlo después de crear
        WorkoutSession.objects.filter(pk=session.pk).update(date=date(2026, 1, 8))

        # Fecha distinta a otros tests para no chocar con dedup diario
        with self._freeze_utc(2026, 1, 20, 9, 0):
            send_inactivity_alerts()

        self.assertEqual(mock_push.call_count, 1)
        _kwargs = mock_push.call_args.kwargs
        self.assertIn("12 días", _kwargs["body"])
        self.assertNotIn("4 días", _kwargs["body"])

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_workout_reminder_matches_hour_only(self, mock_push):
        from apps.notifications.tasks import send_workout_reminders

        self.prefs.workout_hour = 9
        self.prefs.workout_minute = 30
        self.prefs.workout_days = [2]
        self.prefs.save()

        # 2026-01-14 es miércoles; 08:00 UTC = 09:00 Madrid
        with self._freeze_utc(2026, 1, 14, 8, 0):
            count = send_workout_reminders()
        self.assertEqual(count, 1)
        self.assertEqual(mock_push.call_count, 1)

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_body_progress_skips_when_measure_logged(self, mock_push):
        from apps.users.models import BodyMeasures
        from apps.notifications.tasks import send_body_progress_reminders

        self.prefs.body_progress_enabled = True
        self.prefs.body_progress_day_of_week = 2
        self.prefs.body_progress_hour = 10
        self.prefs.body_progress_frequency = "weekly"
        self.prefs.save()

        BodyMeasures.objects.create(
            user=self.user,
            weight=75.0,
            date=date(2026, 1, 12),
        )

        # 2026-01-13 es martes (weekday 1)... need day 2 = Wednesday Jan 14
        # 09:00 UTC = 10:00 Madrid on Jan 14 2026 (Wednesday)
        with self._freeze_utc(2026, 1, 14, 9, 0):
            count = send_body_progress_reminders()
        self.assertEqual(count, 0)
        mock_push.assert_not_called()

    @patch("apps.notifications.tasks.send_push", return_value=True)
    def test_weekly_summary_counts_local_week(self, mock_push):
        from apps.workouts.models import WorkoutSession
        from apps.notifications.tasks import send_weekly_summaries

        self.prefs.weekly_summary_enabled = True
        self.prefs.weekly_summary_day_of_week = 6
        self.prefs.weekly_summary_hour = 20
        self.prefs.save()

        for d in (date(2026, 1, 11), date(2026, 1, 12), date(2026, 1, 14)):
            session = WorkoutSession.objects.create(user=self.user, is_completed=True)
            WorkoutSession.objects.filter(pk=session.pk).update(date=d)

        # Domingo 2026-01-18; 19:00 UTC = 20:00 Madrid
        with self._freeze_utc(2026, 1, 18, 19, 0):
            send_weekly_summaries()

        self.assertEqual(mock_push.call_count, 1)
        self.assertIn("3 entrenamiento", mock_push.call_args.kwargs["body"])
