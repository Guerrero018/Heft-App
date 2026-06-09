from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.routines.models import Routine
from apps.users.models import BodyMeasures
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()


class ExportAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='exportuser',
            email='export@test.com',
            password='testpass123',
        )
        self.other = User.objects.create_user(
            username='otherexport',
            email='otherexport@test.com',
            password='testpass123',
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            name='Press banca',
            muscle_group='pecho',
            exercise_type='barra',
            is_global=True,
        )
        self.routine_a = Routine.objects.create(user=self.user, name='Push', is_active=True)
        self.routine_b = Routine.objects.create(user=self.user, name='Pull', is_active=True)

        old_date = date(2025, 6, 1)
        new_date = date(2026, 2, 1)
        self._create_workout(self.routine_a, old_date, 60.0)
        self._create_workout(self.routine_a, new_date, 80.0)
        self._create_workout(self.routine_b, new_date, 70.0)

        BodyMeasures.objects.create(user=self.user, weight=78.0, date=date(2025, 12, 1))
        BodyMeasures.objects.create(user=self.user, weight=80.0, date=date(2026, 3, 1))

    def _create_workout(self, routine, workout_date, weight):
        session = WorkoutSession.objects.create(
            user=self.user,
            routine=routine,
            name=f'Workout {workout_date}',
            start_time=timezone.now(),
            end_time=timezone.now() + timedelta(hours=1),
            is_completed=True,
        )
        WorkoutSession.objects.filter(pk=session.pk).update(date=workout_date)
        session.refresh_from_db()
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=weight,
            reps=8,
            is_completed=True,
        )
        return session

    def test_preview_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.post('/api/exports/preview/', {})
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_preview_counts_with_date_filter(self):
        response = self.client.post(
            '/api/exports/preview/',
            {
                'date_from': '2026-01-01',
                'include_workouts': True,
                'include_body_measures': True,
                'include_prs': True,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['workouts_count'], 2)
        self.assertEqual(response.data['body_measures_count'], 1)
        self.assertEqual(response.data['prs_count'], 1)

    def test_preview_filters_by_routine(self):
        response = self.client.post(
            '/api/exports/preview/',
            {
                'routine_id': self.routine_b.id,
                'date_from': '2026-01-01',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['workouts_count'], 1)

    def test_download_csv_returns_attachment(self):
        response = self.client.post(
            '/api/exports/download/',
            {
                'format': 'csv',
                'date_from': '2026-01-01',
                'routine_id': self.routine_a.id,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('attachment', response['Content-Disposition'])
        self.assertTrue(
            response['Content-Type'].startswith('text/csv')
            or response['Content-Type'].startswith('application/zip'),
        )
        self.assertGreater(len(response.content), 20)

    def test_download_pdf_returns_pdf(self):
        response = self.client.post(
            '/api/exports/download/',
            {'format': 'pdf', 'include_body_measures': True},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response['Content-Type'].startswith('application/pdf'))
        self.assertTrue(response.content.startswith(b'%PDF'))

    def test_cannot_export_other_users_routine(self):
        other_routine = Routine.objects.create(user=self.other, name='Ajena', is_active=True)
        response = self.client.post(
            '/api/exports/preview/',
            {'routine_id': other_routine.id},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_requires_at_least_one_dataset(self):
        response = self.client.post(
            '/api/exports/preview/',
            {
                'include_workouts': False,
                'include_body_measures': False,
                'include_prs': False,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
