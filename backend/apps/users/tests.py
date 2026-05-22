from datetime import timedelta
from unittest.mock import patch

from django.core import mail
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from datetime import date

from rest_framework_simplejwt.tokens import RefreshToken

from .models import BodyMeasures, PasswordResetCode, User


@override_settings(
    EMAIL_BACKEND="django.core.mail.backends.locmem.EmailBackend",
    DEFAULT_FROM_EMAIL="no-reply@test.local",
)
class PasswordResetFlowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="passwordreset",
            email="password-reset@test.local",
            password="StartPass123!",
        )
        self.request_url = "/api/auth/password-reset/request/"
        self.confirm_url = "/api/auth/password-reset/confirm/"

    def _request_code(self, code=123456, email=None):
        with patch("apps.users.views.secrets.randbelow", return_value=code):
            response = self.client.post(
                self.request_url,
                {"email": email or self.user.email},
                format="json",
            )
        return response

    def _confirm_code(self, code, new_password, confirm_password=None):
        return self.client.post(
            self.confirm_url,
            {
                "email": self.user.email,
                "code": code,
                "new_password": new_password,
                "confirm_password": confirm_password or new_password,
            },
            format="json",
        )

    def test_request_fails_for_unknown_email(self):
        response = self.client.post(
            self.request_url,
            {"email": "missing@test.local"},
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("email", response.data)

    def test_request_sends_email_with_recovery_code(self):
        response = self._request_code(code=654321)

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn("654321", mail.outbox[0].body)

        reset_code = PasswordResetCode.objects.get(user=self.user)
        self.assertIsNone(reset_code.used_at)
        self.assertGreater(reset_code.expires_at, timezone.now())

    def test_confirm_rejects_wrong_code(self):
        self._request_code(code=123456)

        response = self._confirm_code("000000", "ResetPass123!")

        self.assertEqual(response.status_code, 400)
        self.assertIn("code", response.data)

        reset_code = PasswordResetCode.objects.get(user=self.user)
        self.assertEqual(reset_code.attempts, 1)

    def test_confirm_rejects_expired_code(self):
        self._request_code(code=123456)
        reset_code = PasswordResetCode.objects.get(user=self.user)
        reset_code.expires_at = timezone.now() - timedelta(minutes=1)
        reset_code.save(update_fields=["expires_at"])

        response = self._confirm_code("123456", "ResetPass123!")

        self.assertEqual(response.status_code, 400)
        self.assertIn("code", response.data)

    def test_confirm_rejects_mismatched_passwords(self):
        self._request_code(code=123456)

        response = self._confirm_code(
            "123456",
            "ResetPass123!",
            confirm_password="OtherPass123!",
        )

        self.assertEqual(response.status_code, 400)
        self.assertIn("confirm_password", response.data)

    def test_confirm_rejects_weak_password(self):
        self._request_code(code=123456)

        response = self._confirm_code("123456", "12345678")

        self.assertEqual(response.status_code, 400)
        self.assertIn("non_field_errors", response.data)

    def test_used_code_cannot_be_reused(self):
        self._request_code(code=123456)

        first_response = self._confirm_code("123456", "FreshPass123!")
        second_response = self._confirm_code("123456", "AnotherPass123!")

        self.assertEqual(first_response.status_code, 200)
        self.assertEqual(second_response.status_code, 400)
        self.assertIn("code", second_response.data)

        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("FreshPass123!"))

    def test_second_code_invalidates_first(self):
        first_response = self._request_code(code=111111)
        second_response = self._request_code(code=222222)

        stale_response = self._confirm_code("111111", "OldCodePass123!")
        fresh_response = self._confirm_code("222222", "NewestPass123!")

        self.assertEqual(first_response.status_code, 200)
        self.assertEqual(second_response.status_code, 200)
        self.assertEqual(stale_response.status_code, 400)
        self.assertEqual(fresh_response.status_code, 200)

        codes = list(PasswordResetCode.objects.filter(user=self.user).order_by("-created_at"))
        self.assertEqual(len(codes), 2)
        self.assertIsNotNone(codes[1].used_at)


class BodyMeasuresAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="bodytrack",
            email="body@test.local",
            password="TestPass123!",
            weight=80.0,
        )
        refresh = RefreshToken.for_user(self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f"Bearer {refresh.access_token}")
        self.base_url = "/api/body-measures/"

    def test_create_entry_syncs_user_weight(self):
        response = self.client.post(
            self.base_url,
            {"weight": 78.5, "date": "2026-05-20"},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        self.user.refresh_from_db()
        self.assertEqual(self.user.weight, 78.5)

    def test_weight_history_ordered_by_date(self):
        BodyMeasures.objects.create(user=self.user, weight=80, date=date(2026, 5, 1))
        BodyMeasures.objects.create(user=self.user, weight=79, date=date(2026, 5, 10))

        response = self.client.get(f"{self.base_url}weight-history/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.data), 2)
        self.assertEqual(response.data[0]["weight"], 80)
        self.assertEqual(response.data[1]["weight"], 79)

    def test_cannot_access_other_users_entries(self):
        other = User.objects.create_user(
            username="other",
            email="other@test.local",
            password="TestPass123!",
        )
        entry = BodyMeasures.objects.create(
            user=other, weight=90, date=date(2026, 5, 1)
        )

        response = self.client.get(f"{self.base_url}{entry.id}/")
        self.assertEqual(response.status_code, 404)

    def test_delete_reverts_user_weight_to_previous_entry(self):
        BodyMeasures.objects.create(user=self.user, weight=80, date=date(2026, 5, 1))
        latest = BodyMeasures.objects.create(
            user=self.user, weight=75, date=date(2026, 5, 15)
        )
        self.user.weight = 75
        self.user.save(update_fields=["weight"])

        response = self.client.delete(f"{self.base_url}{latest.id}/")

        self.assertEqual(response.status_code, 204)
        self.user.refresh_from_db()
        self.assertEqual(self.user.weight, 80)
