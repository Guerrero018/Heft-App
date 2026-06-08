from datetime import timedelta
from unittest.mock import patch

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.achievements.catalog import achievement_catalog_entries, load_achievement_catalog
from apps.achievements.models import Achievement, UserAchievement
from apps.achievements.services import sync_user_achievements
from apps.exercises.models import Exercise
from apps.routines.models import Routine
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()


class AchievementCatalogTests(APITestCase):
    def test_catalog_has_75_entries(self):
        self.assertEqual(len(achievement_catalog_entries()), 75)

    def test_load_catalog(self):
        load_achievement_catalog()
        self.assertEqual(Achievement.objects.count(), 75)


class AchievementEvaluatorTests(APITestCase):
    def setUp(self):
        load_achievement_catalog()
        self.user = User.objects.create_user(
            username="lifter",
            email="lifter@test.com",
            password="pass12345",
        )
        self.exercise = Exercise.objects.create(
            name="press de banca con barra",
            muscle_group="pecho",
            exercise_type="barra",
            is_global=True,
        )

    def _workout_with_bench(self, weight: float, *, days_ago: int = 0):
        when = timezone.now() - timedelta(days=days_ago)
        session = WorkoutSession.objects.create(
            user=self.user,
            name="Push",
            is_completed=True,
            date=when.date(),
            start_time=when,
            end_time=when + timedelta(minutes=60),
        )
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=weight,
            reps=1,
            is_completed=True,
        )
        return session

    def test_bench_press_gold_unlocked_in_db(self):
        self._workout_with_bench(140)
        records = sync_user_achievements(self.user).records
        gold = next(r for r in records if r.achievement.slug == "bench_press_gold")
        self.assertTrue(gold.is_unlocked)
        self.assertIsNotNone(gold.unlocked_at)

    def test_first_workout_unlocked(self):
        self._workout_with_bench(60)
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="first_workout"
        )
        self.assertTrue(record.is_unlocked)

    @patch("apps.achievements.evaluator._compute_week_streak", return_value=4)
    def test_week_streak_4_unlocked(self, _mock_streak):
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="week_streak_4"
        )
        self.assertTrue(record.is_unlocked)

    def test_first_pr_unlocked_after_improvement(self):
        self._workout_with_bench(60, days_ago=2)
        self._workout_with_bench(70, days_ago=0)
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="first_pr"
        )
        self.assertTrue(record.is_unlocked)

    def test_onboarding_done_unlocked(self):
        self.user.is_onboarded = True
        self.user.save(update_fields=["is_onboarded"])
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="onboarding_done"
        )
        self.assertTrue(record.is_unlocked)

    def test_profile_photo_unlocked(self):
        self.user.profile_picture.save(
            f"user_{self.user.id}/avatar.jpg",
            SimpleUploadedFile("avatar.jpg", b"fake-image"),
            save=True,
        )
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="profile_photo"
        )
        self.assertTrue(record.is_unlocked)

    def test_routine_first_unlocked(self):
        Routine.objects.create(user=self.user, name="Push day")
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="routine_first"
        )
        self.assertTrue(record.is_unlocked)

    def test_custom_exercise_unlocked(self):
        Exercise.objects.create(
            name="curl personalizado",
            muscle_group="biceps",
            exercise_type="mancuernas",
            is_global=False,
            user=self.user,
        )
        sync_user_achievements(self.user)
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="custom_exercise"
        )
        self.assertTrue(record.is_unlocked)

    def test_sync_returns_newly_unlocked_slugs(self):
        sync_user_achievements(self.user)
        # bulk_create no dispara post_save; el sync manual detecta el cambio.
        User.objects.filter(pk=self.user.pk).update(is_onboarded=True)
        self.user.refresh_from_db()
        result = sync_user_achievements(self.user)
        self.assertIn("onboarding_done", result.newly_unlocked)


class AchievementSignalTests(APITestCase):
    def setUp(self):
        load_achievement_catalog()
        self.user = User.objects.create_user(
            username="signaluser",
            email="signal@test.com",
            password="pass12345",
        )
        sync_user_achievements(self.user)

    def test_routine_signal_syncs_achievement(self):
        Routine.objects.create(user=self.user, name="Leg day")
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="routine_first"
        )
        self.assertTrue(record.is_unlocked)

    def test_custom_exercise_signal_syncs_achievement(self):
        Exercise.objects.create(
            name="press inventado",
            muscle_group="pecho",
            exercise_type="barra",
            is_global=False,
            user=self.user,
        )
        record = UserAchievement.objects.get(
            user=self.user, achievement__slug="custom_exercise"
        )
        self.assertTrue(record.is_unlocked)


class UserAchievementsApiTests(APITestCase):
    def setUp(self):
        load_achievement_catalog()
        self.user = User.objects.create_user(
            username="apiuser",
            email="api@test.com",
            password="pass12345",
        )
        self.client.force_authenticate(user=self.user)

    def test_get_achievements(self):
        response = self.client.get("/api/achievements/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total_count"], 75)
        self.assertIn("achievements", response.data)
        self.assertEqual(len(response.data["achievements"]), 75)
        self.assertEqual(response.data["newly_unlocked"], [])

    def test_get_reads_without_full_eval_when_records_exist(self):
        sync_user_achievements(self.user)
        with patch("apps.achievements.services.evaluate_achievement") as mock_eval:
            response = self.client.get("/api/achievements/")
            mock_eval.assert_not_called()
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_post_sync_returns_newly_unlocked(self):
        sync_user_achievements(self.user)
        Routine.objects.bulk_create([Routine(user=self.user, name="Upper")])
        response = self.client.post("/api/achievements/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("routine_first", response.data["newly_unlocked"])
        record = next(
            a for a in response.data["achievements"] if a["id"] == "routine_first"
        )
        self.assertTrue(record["is_unlocked"])
