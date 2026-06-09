from datetime import date, datetime, timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.test import SimpleTestCase
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.statistics.services import (
    _compute_week_streak,
    _period_date_bounds,
    _resolve_period,
    _week_start_monday,
    build_user_statistics,
)
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()

_FIXED_TODAY = date(2026, 5, 15)


class StatisticsServiceUnitTests(SimpleTestCase):
    def test_week_start_monday(self):
        self.assertEqual(_week_start_monday(date(2026, 5, 15)), date(2026, 5, 11))

    def test_resolve_period_invalid_defaults_to_week(self):
        key, start, end = _resolve_period("nope")
        self.assertEqual(key, "week")
        self.assertIsNotNone(start)
        self.assertLess(start, end)

    def test_period_date_bounds_all(self):
        with patch(
            "apps.statistics.services.timezone.localdate",
            return_value=_FIXED_TODAY,
        ):
            start, end = _period_date_bounds("all")
        self.assertIsNone(start)
        self.assertEqual(end, _FIXED_TODAY)

    @patch("apps.statistics.services.timezone.localdate", return_value=_FIXED_TODAY)
    def test_compute_week_streak_counts_consecutive_weeks(self, _mock_today):
        week_start = _week_start_monday(_FIXED_TODAY)
        dates = [
            week_start,
            week_start + timedelta(days=1),
            week_start - timedelta(days=7),
        ]
        streak = _compute_week_streak(dates, target_days_per_week=2)
        self.assertGreaterEqual(streak, 1)


class UserStatisticsTests(APITestCase):
    def setUp(self):
        self._localdate_patcher = patch(
            "apps.statistics.services.timezone.localdate",
            return_value=_FIXED_TODAY,
        )
        self._localdate_patcher.start()

        self.user = User.objects.create_user(
            username="statsuser",
            email="stats@test.com",
            password="testpass123",
            workout_days_per_week=3,
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            name="Press Banca",
            muscle_group="pecho",
            exercise_type="barra",
            is_global=True,
        )

        session = WorkoutSession.objects.create(
            user=self.user,
            name="Push",
            start_time=timezone.make_aware(
                datetime.combine(_FIXED_TODAY, datetime.min.time()),
            ),
            end_time=timezone.make_aware(
                datetime.combine(_FIXED_TODAY, datetime.min.time()),
            )
            + timedelta(hours=1),
            is_completed=True,
        )
        # auto_now_add overwrites date on create; set explicitly for period bounds.
        WorkoutSession.objects.filter(pk=session.pk).update(date=_FIXED_TODAY)
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=80,
            reps=8,
            is_completed=True,
        )
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=2,
            weight=75,
            reps=10,
            is_completed=True,
        )

    def tearDown(self):
        self._localdate_patcher.stop()

    def test_statistics_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get("/api/statistics/")
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_statistics_returns_real_aggregates(self):
        response = self.client.get("/api/statistics/?period=week")
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        data = response.data
        self.assertEqual(data["period"], "week")
        self.assertEqual(data["summary"]["total_workouts"], 1)
        self.assertGreater(data["summary"]["total_volume_kg"], 0)
        self.assertEqual(len(data["exercise_progress"]), 1)
        self.assertEqual(
            data["exercise_progress"][0]["exercise_name"], "Press Banca"
        )
        session_volume = 80 * 8 + 75 * 10
        self.assertEqual(
            data["exercise_progress"][0]["data_points"][0]["volume"],
            session_volume,
        )
        self.assertIn("chest", data["muscle_map"]["front"])

    def test_calendar_week_period_bounds(self):
        response = self.client.get("/api/statistics/?period=calendar_week")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data
        self.assertEqual(data["period"], "calendar_week")
        # Lunes 11 may – domingo 17 may 2026 (today fijado al 15)
        self.assertEqual(data["period_start"], "2026-05-11")
        self.assertEqual(data["period_end"], "2026-05-17")
        self.assertEqual(data["summary"]["total_workouts"], 1)

    def test_invalid_period_defaults_to_week(self):
        response = self.client.get("/api/statistics/?period=invalid")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["period"], "week")

    def test_month_period(self):
        response = self.client.get("/api/statistics/?period=month")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["period"], "month")
        self.assertGreaterEqual(response.data["summary"]["total_workouts"], 1)

    def test_all_period_includes_history(self):
        response = self.client.get("/api/statistics/?period=all")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["period"], "all")
        self.assertIsNone(response.data["period_start"])

    def test_empty_user_statistics(self):
        empty_user = User.objects.create_user(
            username="emptystats",
            email="empty@test.com",
            password="testpass123",
        )
        self.client.force_authenticate(user=empty_user)
        response = self.client.get("/api/statistics/?period=week")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["summary"]["total_workouts"], 0)
        self.assertEqual(response.data["summary"]["total_volume_kg"], 0)
