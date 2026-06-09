"""Definición de plantillas oficiales Heft (biblioteca pública)."""

from __future__ import annotations

from typing import Any

# Cada ejercicio: name, muscle_group, exercise_type, sets, reps, weight_kg, rest_seconds
OFFICIAL_TEMPLATES: list[dict[str, Any]] = [
    {
        'name': 'Full Body — Principiante',
        'description': (
            'Rutina de cuerpo completo 2–3 días/semana. Movimientos básicos compuestos '
            'para empezar con buena técnica.'
        ),
        'exercises': [
            ('Sentadilla', 'cuadriceps', 'barra', 3, 10, 40, 120),
            ('Press de banca', 'pecho', 'barra', 3, 10, 30, 90),
            ('Remo con barra', 'espalda', 'barra', 3, 10, 30, 90),
            ('Press militar', 'hombros', 'barra', 3, 10, 20, 90),
            ('Curl de bíceps', 'biceps', 'barra', 2, 12, 15, 60),
        ],
    },
    {
        'name': 'Full Body — Intermedio',
        'description': (
            'Cuerpo completo con más volumen. Ideal si ya dominas los básicos y '
            'entrenas 3 días por semana.'
        ),
        'exercises': [
            ('Sentadilla', 'cuadriceps', 'barra', 4, 8, 55, 120),
            ('Press de banca', 'pecho', 'barra', 4, 8, 50, 120),
            ('Peso muerto rumano', 'isquiotibiales', 'barra', 3, 10, 50, 120),
            ('Remo con barra', 'espalda', 'barra', 4, 10, 40, 90),
            ('Press militar con mancuernas', 'hombros', 'mancuernas', 3, 10, 16, 90),
            ('Curl de bíceps', 'biceps', 'mancuernas', 3, 12, 12, 60),
        ],
    },
    {
        'name': 'Push — Pecho, Hombros y Tríceps',
        'description': (
            'Día de empuje clásico (PPL). Pecho como prioridad, hombros y tríceps '
            'de apoyo. Descansa 48–72 h antes del siguiente push.'
        ),
        'exercises': [
            ('Press de banca', 'pecho', 'barra', 4, 8, 50, 120),
            ('Press inclinado con mancuernas', 'pecho', 'mancuernas', 3, 10, 22, 90),
            ('Press militar', 'hombros', 'barra', 3, 10, 30, 90),
            ('Elevaciones laterales', 'hombros', 'mancuernas', 3, 15, 8, 60),
            ('Fondos en paralelas', 'triceps', 'peso_corporal', 3, 10, 0, 90),
            ('Extensión de tríceps en polea', 'triceps', 'polea', 3, 12, 25, 60),
        ],
    },
    {
        'name': 'Pull — Espalda y Bíceps',
        'description': (
            'Día de tirón (PPL). Espalda con remo y jalón; bíceps al final. '
            'Mantén la espalda neutra en el peso muerto.'
        ),
        'exercises': [
            ('Peso muerto', 'espalda', 'barra', 4, 6, 60, 150),
            ('Remo con barra', 'espalda', 'barra', 4, 10, 40, 90),
            ('Jalón al pecho', 'espalda', 'polea', 3, 12, 45, 90),
            ('Remo en polea baja', 'espalda', 'polea', 3, 12, 40, 90),
            ('Curl con barra', 'biceps', 'barra', 3, 12, 20, 60),
            ('Curl martillo', 'biceps', 'mancuernas', 3, 12, 12, 60),
        ],
    },
    {
        'name': 'Leg — Piernas y Glúteos',
        'description': (
            'Día de pierna (PPL). Cuádriceps, femorales y gemelos. Calienta bien '
            'antes de sentadilla o prensa.'
        ),
        'exercises': [
            ('Sentadilla', 'cuadriceps', 'barra', 4, 8, 50, 150),
            ('Prensa de piernas', 'cuadriceps', 'maquina', 3, 12, 80, 120),
            ('Peso muerto rumano', 'isquiotibiales', 'barra', 3, 10, 50, 120),
            ('Curl femoral en máquina', 'isquiotibiales', 'maquina', 3, 12, 35, 90),
            ('Elevación de gemelos de pie', 'gemelos', 'maquina', 4, 15, 40, 60),
            ('Hip thrust', 'gluteos', 'barra', 3, 12, 40, 90),
        ],
    },
    {
        'name': 'Upper — Tren superior',
        'description': (
            'Torso completo en una sesión. Buena opción en rutina upper/lower '
            'de 4 días por semana.'
        ),
        'exercises': [
            ('Press de banca', 'pecho', 'barra', 4, 8, 50, 120),
            ('Remo con barra', 'espalda', 'barra', 4, 10, 40, 90),
            ('Press militar', 'hombros', 'barra', 3, 10, 30, 90),
            ('Jalón al pecho', 'espalda', 'polea', 3, 12, 45, 90),
            ('Curl de bíceps', 'biceps', 'mancuernas', 3, 12, 12, 60),
            ('Extensión de tríceps en polea', 'triceps', 'polea', 3, 12, 25, 60),
        ],
    },
    {
        'name': 'Lower — Tren inferior',
        'description': (
            'Piernas y glúteos en una sesión. Complementa el día Upper en un '
            'esquema upper/lower.'
        ),
        'exercises': [
            ('Sentadilla', 'cuadriceps', 'barra', 4, 8, 55, 150),
            ('Peso muerto rumano', 'isquiotibiales', 'barra', 3, 10, 50, 120),
            ('Zancadas con mancuernas', 'cuadriceps', 'mancuernas', 3, 10, 14, 90),
            ('Curl femoral en máquina', 'isquiotibiales', 'maquina', 3, 12, 35, 90),
            ('Elevación de gemelos de pie', 'gemelos', 'maquina', 4, 15, 40, 60),
        ],
    },
    {
        'name': 'Fuerza básica — 5×5',
        'description': (
            'Plantilla inspirada en programas tipo Starting Strong: pocos ejercicios '
            'compuestos, series pesadas de 5 repeticiones.'
        ),
        'exercises': [
            ('Sentadilla', 'cuadriceps', 'barra', 5, 5, 50, 180),
            ('Press de banca', 'pecho', 'barra', 5, 5, 45, 180),
            ('Peso muerto', 'espalda', 'barra', 1, 5, 70, 180),
            ('Press militar', 'hombros', 'barra', 5, 5, 30, 180),
            ('Remo con barra', 'espalda', 'barra', 5, 5, 40, 120),
        ],
    },
]


def seed_official_templates(apps, *, rename_legacy: bool = True) -> int:
    """Crea plantillas oficiales que aún no existan. Devuelve cuántas se crearon."""
    User = apps.get_model('users', 'User')
    Exercise = apps.get_model('exercises', 'Exercise')
    Routine = apps.get_model('routines', 'Routine')
    RoutineExercise = apps.get_model('routines', 'RoutineExercise')

    from django.utils import timezone

    owner = (
        User.objects.filter(is_superuser=True).first()
        or User.objects.filter(is_staff=True).first()
        or User.objects.order_by('id').first()
    )
    if owner is None:
        return 0

    if rename_legacy:
        Routine.objects.filter(
            is_official=True,
            name='Push Pull Legs',
        ).update(
            name='Push — Día de empuje (v1)',
            description=(
                'Versión inicial de plantilla push. Usa la plantilla '
                '"Push — Pecho, Hombros y Tríceps" para la versión completa.'
            ),
        )
        Routine.objects.filter(
            is_official=True,
            name='Full Body Principiante',
        ).update(name='Full Body — Principiante (v1)')

    created = 0

    def get_or_create_exercise(name, muscle_group, exercise_type):
        exercise, _ = Exercise.objects.get_or_create(
            name=name,
            defaults={
                'muscle_group': muscle_group,
                'exercise_type': exercise_type,
                'is_global': True,
            },
        )
        return exercise

    for template in OFFICIAL_TEMPLATES:
        if Routine.objects.filter(
            user=owner,
            name=template['name'],
            is_official=True,
        ).exists():
            continue

        routine = Routine.objects.create(
            user=owner,
            name=template['name'],
            description=template['description'],
            is_active=True,
            is_public=True,
            is_official=True,
            published_at=timezone.now(),
        )
        for order, row in enumerate(template['exercises'], start=1):
            ex_name, muscle, ex_type, sets, reps, weight, rest = row
            exercise = get_or_create_exercise(ex_name, muscle, ex_type)
            RoutineExercise.objects.create(
                routine=routine,
                exercise=exercise,
                order=order,
                target_sets=sets,
                target_reps=reps,
                target_weight=weight,
                rest_time_seconds=rest,
            )
        created += 1

    return created
