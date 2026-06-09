from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.workouts.models import WorkoutSession, WorkoutSet

User = get_user_model()


class ExerciseApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='exuser',
            email='ex@test.com',
            password='testpass123',
        )
        self.other = User.objects.create_user(
            username='other',
            email='other@test.com',
            password='testpass123',
        )
        self.client.force_authenticate(user=self.user)

        self.bench = Exercise.objects.create(
            name='Press Banca',
            muscle_group='pecho',
            exercise_type='barra',
            is_global=True,
        )
        Exercise.objects.create(
            name='Curl Mancuerna',
            muscle_group='biceps',
            exercise_type='mancuernas',
            is_global=True,
        )
        Exercise.objects.create(
            name='Privado Ajeno',
            muscle_group='pecho',
            exercise_type='barra',
            is_global=False,
            user=self.other,
        )

    def test_list_is_paginated(self):
        response = self.client.get('/api/exercises/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('results', response.data)
        self.assertIn('count', response.data)
        self.assertLessEqual(len(response.data['results']), 40)

    def test_filter_by_muscle_group(self):
        response = self.client.get('/api/exercises/?muscle_group=pecho')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in response.data['results']]
        self.assertIn('Press Banca', names)
        self.assertNotIn('Curl Mancuerna', names)

    def test_search_by_name(self):
        response = self.client.get('/api/exercises/?search=curl')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in response.data['results']]
        self.assertEqual(names, ['Curl Mancuerna'])

    def test_popular_orders_by_usage(self):
        session = WorkoutSession.objects.create(
            user=self.user,
            name='Push',
            is_completed=True,
        )
        curl = Exercise.objects.get(name='Curl Mancuerna')
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=curl,
            set_number=1,
            weight=10,
            reps=12,
            is_completed=True,
        )
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=curl,
            set_number=2,
            weight=10,
            reps=12,
            is_completed=True,
        )
        WorkoutSet.objects.create(
            workout_session=session,
            exercise=self.bench,
            set_number=1,
            weight=60,
            reps=8,
            is_completed=True,
        )

        response = self.client.get('/api/exercises/popular/?limit=5')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsInstance(response.data, list)
        self.assertGreaterEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['name'], 'Curl Mancuerna')

    def test_popular_fallback_without_history(self):
        response = self.client.get('/api/exercises/popular/?limit=3')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertGreater(len(response.data), 0)
        names = {item['name'] for item in response.data}
        self.assertNotIn('Privado Ajeno', names)

    def test_filter_by_exercise_type(self):
        response = self.client.get('/api/exercises/?exercise_type=mancuernas')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in response.data['results']]
        self.assertEqual(names, ['Curl Mancuerna'])

    def test_create_custom_exercise(self):
        response = self.client.post(
            '/api/exercises/',
            {
                'name': 'Mi ejercicio',
                'muscle_group': 'pecho',
                'exercise_type': 'barra',
                'is_global': False,
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'Mi ejercicio')
        self.assertFalse(response.data['is_global'])

    def test_private_exercise_from_other_user_not_listed(self):
        response = self.client.get('/api/exercises/')
        names = [item['name'] for item in response.data['results']]
        self.assertNotIn('Privado Ajeno', names)

    def test_list_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get('/api/exercises/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
