from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()


class UserStatisticsTests(APITestCase):
    def setUp(self):
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
            start_time=timezone.now() - timedelta(days=1),
            end_time=timezone.now() - timedelta(days=1) + timedelta(hours=1),
            is_completed=True,
        )
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
        self.assertIn("chest", data["muscle_map"]["front"])
