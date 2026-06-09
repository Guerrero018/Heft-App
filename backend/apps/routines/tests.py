from django.contrib.auth import get_user_model
from rest_framework import status
from rest_framework.test import APITestCase

from apps.exercises.models import Exercise
from apps.routines.models import Routine, RoutineExercise

User = get_user_model()


class RoutineApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='routineuser',
            email='routine@test.com',
            password='testpass123',
        )
        self.other = User.objects.create_user(
            username='otherroutine',
            email='otherroutine@test.com',
            password='testpass123',
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            name='Press Banca',
            muscle_group='pecho',
            exercise_type='barra',
            is_global=True,
        )
        self.other_routine = Routine.objects.create(
            user=self.other,
            name='Ajena',
            is_active=True,
        )

    def _exercise_block(self, order=1):
        return {
            'exercise': self.exercise.id,
            'order': order,
            'target_sets': 3,
            'target_reps': 10,
            'target_weight': 60.0,
            'rest_time_seconds': 90,
        }

    def test_list_requires_auth(self):
        self.client.force_authenticate(user=None)
        response = self.client.get('/api/routines/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_list_returns_only_own_routines(self):
        own = Routine.objects.create(user=self.user, name='Mía', is_active=True)
        response = self.client.get('/api/routines/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(own.id, ids)
        self.assertNotIn(self.other_routine.id, ids)

    def test_create_routine_with_exercises(self):
        response = self.client.post(
            '/api/routines/',
            {
                'name': 'Push',
                'description': 'Pecho y tríceps',
                'is_active': True,
                'exercises': [self._exercise_block()],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(len(response.data['exercises']), 1)
        self.assertEqual(response.data['exercises'][0]['exercise_name'], 'Press Banca')

        routine = Routine.objects.get(pk=response.data['id'])
        self.assertEqual(routine.user, self.user)
        self.assertEqual(routine.exercises.count(), 1)

    def test_filter_active_routines(self):
        active = Routine.objects.create(user=self.user, name='Activa', is_active=True)
        Routine.objects.create(user=self.user, name='Archivada', is_active=False)

        response = self.client.get('/api/routines/?is_active=true')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertEqual(ids, [active.id])

        response = self.client.get('/api/routines/?is_active=false')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = [item['name'] for item in response.data]
        self.assertEqual(names, ['Archivada'])

    def test_update_routine_replaces_exercises(self):
        routine = Routine.objects.create(user=self.user, name='Original')
        RoutineExercise.objects.create(
            routine=routine,
            exercise=self.exercise,
            order=1,
            target_sets=2,
            target_reps=8,
            target_weight=50,
        )

        curl = Exercise.objects.create(
            name='Curl',
            muscle_group='biceps',
            exercise_type='mancuernas',
            is_global=True,
        )

        response = self.client.patch(
            f'/api/routines/{routine.id}/',
            {
                'name': 'Actualizada',
                'is_active': False,
                'exercises': [
                    {
                        'exercise': curl.id,
                        'order': 1,
                        'target_sets': 4,
                        'target_reps': 12,
                        'target_weight': 15,
                        'rest_time_seconds': 60,
                    },
                ],
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        routine.refresh_from_db()
        self.assertEqual(routine.name, 'Actualizada')
        self.assertFalse(routine.is_active)
        self.assertEqual(routine.exercises.count(), 1)
        self.assertEqual(routine.exercises.first().exercise.name, 'Curl')

    def test_delete_routine(self):
        routine = Routine.objects.create(user=self.user, name='Eliminar')
        RoutineExercise.objects.create(
            routine=routine,
            exercise=self.exercise,
            order=1,
            target_sets=1,
            target_reps=10,
            target_weight=20,
        )

        response = self.client.delete(f'/api/routines/{routine.id}/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Routine.objects.filter(pk=routine.id).exists())

    def test_cannot_access_other_users_routine(self):
        response = self.client.get(f'/api/routines/{self.other_routine.id}/')
        self.assertEqual(response.status_code, status.HTTP_404_NOT_FOUND)

    def test_publish_and_unpublish_routine(self):
        routine = Routine.objects.create(user=self.user, name='Publicable')
        RoutineExercise.objects.create(
            routine=routine,
            exercise=self.exercise,
            order=1,
            target_sets=3,
            target_reps=10,
            target_weight=50,
        )

        response = self.client.post(f'/api/routines/{routine.id}/publish/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['is_public'])

        response = self.client.post(f'/api/routines/{routine.id}/unpublish/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['is_public'])

    def test_publish_requires_exercises(self):
        routine = Routine.objects.create(user=self.user, name='Vacía')
        response = self.client.post(f'/api/routines/{routine.id}/publish/')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_share_generates_code(self):
        routine = Routine.objects.create(user=self.user, name='Compartir')
        RoutineExercise.objects.create(
            routine=routine,
            exercise=self.exercise,
            order=1,
            target_sets=3,
            target_reps=10,
            target_weight=50,
        )
        response = self.client.post(f'/api/routines/{routine.id}/share/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(len(response.data['share_code']) >= 6)

        routine.refresh_from_db()
        self.assertEqual(routine.share_code, response.data['share_code'])


class RoutineTemplateApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='templateuser',
            email='template@test.com',
            password='testpass123',
        )
        self.author = User.objects.create_user(
            username='author',
            email='author@test.com',
            password='testpass123',
        )
        self.client.force_authenticate(user=self.user)

        self.exercise = Exercise.objects.create(
            name='Peso muerto',
            muscle_group='piernas',
            exercise_type='barra',
            is_global=True,
        )
        self.public_routine = Routine.objects.create(
            user=self.author,
            name='Plantilla pública',
            description='Para todos',
            is_public=True,
            is_active=True,
        )
        RoutineExercise.objects.create(
            routine=self.public_routine,
            exercise=self.exercise,
            order=1,
            target_sets=4,
            target_reps=6,
            target_weight=80,
        )

    def test_library_lists_public_routines(self):
        response = self.client.get('/api/routine-templates/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        ids = [item['id'] for item in response.data]
        self.assertIn(self.public_routine.id, ids)

    def test_library_detail(self):
        response = self.client.get(f'/api/routine-templates/{self.public_routine.id}/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['author']['username'], 'author')
        self.assertEqual(len(response.data['exercises']), 1)

    def test_import_template_creates_owned_copy(self):
        response = self.client.post(
            f'/api/routine-templates/{self.public_routine.id}/import_template/',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['name'], 'Plantilla pública')

        imported = Routine.objects.get(pk=response.data['id'])
        self.assertEqual(imported.user, self.user)
        self.assertEqual(imported.exercises.count(), 1)

        self.public_routine.refresh_from_db()
        self.assertEqual(self.public_routine.times_imported, 1)

    def test_shared_import_by_code(self):
        self.public_routine.share_code = 'ABC12345'
        self.public_routine.save(update_fields=['share_code'])

        preview = self.client.get('/api/routines/shared/ABC12345/')
        self.assertEqual(preview.status_code, status.HTTP_200_OK)

        response = self.client.post('/api/routines/shared/ABC12345/import/')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertTrue(
            Routine.objects.filter(user=self.user, name='Plantilla pública').exists(),
        )

    def test_cannot_import_own_public_routine(self):
        own_public = Routine.objects.create(
            user=self.user,
            name='Mía pública',
            is_public=True,
        )
        response = self.client.post(
            f'/api/routine-templates/{own_public.id}/import_template/',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
