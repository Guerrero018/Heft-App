from datetime import timedelta

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.routines.models import Routine
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()


def _response_items(data):
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get('results'), list):
        return data['results']
    return []


class WorkoutApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='workoutuser',
            email='workout@test.com',
            password='testpass123',
        )
        self.other = User.objects.create_user(
            username='otherworkout',
            email='otherworkout@test.com',
            password='testpass123',
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            name='Sentadilla',
            muscle_group='cuadriceps',
            exercise_type='barra',
            is_global=True,
        )
        self.routine = Routine.objects.create(
            user=self.user,
            name='Leg Day',
            is_active=True,
        )
        self.other_session = WorkoutSession.objects.create(
            user=self.other,
            name='Ajeno',
            is_completed=True,
        )

    def _payload(self, *, routine=None, sets=None):
        now = timezone.now()
        return {
            'name': 'Sesión test',
            'start_time': now.isoformat(),
            'end_time': (now + timedelta(hours=1)).isoformat(),
            'is_completed': True,
            'routine': routine.id if routine else None,
            'sets': sets
            if sets is not None
            else [
                {
                    'exercise': self.exercise.id,
                    'set_number': 1,
                    'weight': 80.0,
                    'reps': 8,
                    'is_completed': True,
                },
            ],
        }

    def test_list_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get('/api/workouts/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_list_returns_only_own_workouts(self):
        own = WorkoutSession.objects.create(
            user=self.user,
            name='Mío',
            is_completed=True,
        )
        response = self.client.get('/api/workouts/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in _response_items(response.data)]
        self.assertIn(own.id, ids)
        self.assertNotIn(self.other_session.id, ids)

    def test_create_workout_with_sets(self):
        response = self.client.post(
            '/api/workouts/',
            self._payload(routine=self.routine),
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['routine_name'], 'Leg Day')
        self.assertEqual(len(response.data['sets']), 1)
        self.assertEqual(response.data['sets'][0]['exercise_name'], 'Sentadilla')

        session = WorkoutSession.objects.get(pk=response.data['id'])
        self.assertEqual(session.user, self.user)
        self.assertEqual(session.sets.count(), 1)

    def test_filter_by_routine(self):
        matched = WorkoutSession.objects.create(
            user=self.user,
            name='Con rutina',
            routine=self.routine,
            is_completed=True,
        )
        WorkoutSession.objects.create(
            user=self.user,
            name='Sin rutina',
            is_completed=True,
        )

        response = self.client.get(f'/api/workouts/?routine={self.routine.id}')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in _response_items(response.data)]
        self.assertEqual(ids, [matched.id])

    def test_update_workout_merges_sets(self):
        session = WorkoutSession.objects.create(
            user=self.user,
            name='Update',
            is_completed=False,
        )
        existing = WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=60,
            reps=10,
            is_completed=True,
        )

        response = self.client.patch(
            f'/api/workouts/{session.id}/',
            {
                'is_completed': True,
                'sets': [
                    {
                        'id': existing.id,
                        'exercise': self.exercise.id,
                        'set_number': 1,
                        'weight': 65,
                        'reps': 10,
                        'is_completed': True,
                    },
                    {
                        'exercise': self.exercise.id,
                        'set_number': 2,
                        'weight': 70,
                        'reps': 8,
                        'is_completed': True,
                    },
                ],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        session.refresh_from_db()
        self.assertTrue(session.is_completed)
        self.assertEqual(session.sets.count(), 2)
        existing.refresh_from_db()
        self.assertEqual(existing.weight, 65)

    def test_update_removes_omitted_sets(self):
        session = WorkoutSession.objects.create(user=self.user, name='Delete set')
        keep = WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=50,
            reps=12,
        )
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=2,
            weight=55,
            reps=10,
        )

        response = self.client.patch(
            f'/api/workouts/{session.id}/',
            {
                'sets': [
                    {
                        'id': keep.id,
                        'exercise': self.exercise.id,
                        'set_number': 1,
                        'weight': 50,
                        'reps': 12,
                        'is_completed': True,
                    },
                ],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(session.sets.count(), 1)

    def test_delete_workout(self):
        session = WorkoutSession.objects.create(user=self.user, name='Borrar')
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.exercise,
            set_number=1,
            weight=40,
            reps=15,
        )

        response = self.client.delete(f'/api/workouts/{session.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(WorkoutSession.objects.filter(pk=session.id).exists())

    def test_cannot_access_other_users_workout(self):
        response = self.client.get(f'/api/workouts/{self.other_session.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)
