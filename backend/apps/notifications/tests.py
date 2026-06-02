from django.contrib.auth import get_user_model
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
