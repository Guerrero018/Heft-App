from django.db import migrations
from django.utils import timezone


def seed_official_templates(apps, schema_editor):
    User = apps.get_model('users', 'User')
    Exercise = apps.get_model('exercises', 'Exercise')
    Routine = apps.get_model('routines', 'Routine')
    RoutineExercise = apps.get_model('routines', 'RoutineExercise')

    staff = User.objects.filter(is_superuser=True).first()
    if staff is None:
        staff = User.objects.filter(is_staff=True).first()
    if staff is None:
        staff = User.objects.order_by('id').first()
    if staff is None:
        return

    def get_or_create_exercise(name, muscle_group, exercise_type='barra'):
        exercise, _ = Exercise.objects.get_or_create(
            name=name,
            defaults={
                'muscle_group': muscle_group,
                'exercise_type': exercise_type,
                'is_global': True,
            },
        )
        return exercise

    templates = [
        {
            'name': 'Full Body Principiante',
            'description': 'Rutina de cuerpo completo 3 días. Ideal para empezar en el gimnasio.',
            'exercises': [
                ('Sentadilla', 'piernas', 3, 10, 40),
                ('Press de banca', 'pecho', 3, 10, 30),
                ('Remo con barra', 'espalda', 3, 10, 30),
                ('Press militar', 'hombros', 3, 10, 20),
                ('Curl de bíceps', 'biceps', 2, 12, 12),
            ],
        },
        {
            'name': 'Push Pull Legs',
            'description': 'División clásica empuje / tirón / pierna. Plantilla base PPL.',
            'exercises': [
                ('Press de banca', 'pecho', 4, 8, 50),
                ('Press inclinado con mancuernas', 'pecho', 3, 10, 22),
                ('Fondos en paralelas', 'triceps', 3, 10, 0),
                ('Elevaciones laterales', 'hombros', 3, 15, 8),
            ],
        },
    ]

    for template in templates:
        if Routine.objects.filter(
            user=staff,
            name=template['name'],
            is_official=True,
        ).exists():
            continue

        routine = Routine.objects.create(
            user=staff,
            name=template['name'],
            description=template['description'],
            is_active=True,
            is_public=True,
            is_official=True,
            published_at=timezone.now(),
        )
        for order, (ex_name, muscle, sets, reps, weight) in enumerate(
            template['exercises'],
            start=1,
        ):
            exercise = get_or_create_exercise(ex_name, muscle)
            RoutineExercise.objects.create(
                routine=routine,
                exercise=exercise,
                order=order,
                target_sets=sets,
                target_reps=reps,
                target_weight=weight,
                rest_time_seconds=90,
            )


class Migration(migrations.Migration):
    atomic = False

    dependencies = [
        ('routines', '0004_routine_templates'),
    ]

    operations = [
        migrations.RunPython(seed_official_templates, migrations.RunPython.noop),
    ]
