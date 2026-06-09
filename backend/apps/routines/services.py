import secrets

from django.db.models import F
from django.utils import timezone

from .models import Routine, RoutineExercise


def generate_share_code() -> str:
    for _ in range(20):
        code = secrets.token_urlsafe(6).replace('-', '').replace('_', '')[:8].upper()
        if not Routine.objects.filter(share_code=code).exists():
            return code
    raise RuntimeError('No se pudo generar un código de compartir único')


def clone_routine_for_user(
    source: Routine,
    user,
    *,
    name: str | None = None,
    track_import: bool = True,
) -> Routine:
    """Copia una rutina (pública o por código) a la biblioteca del usuario."""
    clone = Routine.objects.create(
        user=user,
        name=name or source.name,
        description=source.description,
        is_active=True,
        source_routine=source,
    )

    for exercise in source.exercises.select_related('exercise').order_by('order'):
        RoutineExercise.objects.create(
            routine=clone,
            exercise=exercise.exercise,
            order=exercise.order,
            target_sets=exercise.target_sets,
            target_reps=exercise.target_reps,
            target_weight=exercise.target_weight,
            rest_time_seconds=exercise.rest_time_seconds,
        )

    if track_import and (source.is_public or source.is_official or source.share_code):
        Routine.objects.filter(pk=source.pk).update(
            times_imported=F('times_imported') + 1,
        )

    return clone


def publish_routine(routine: Routine) -> Routine:
    if routine.exercises.count() == 0:
        raise ValueError('La rutina debe tener al menos un ejercicio para publicarse.')
    routine.is_public = True
    routine.published_at = timezone.now()
    routine.save(update_fields=['is_public', 'published_at', 'updated_at'])
    return routine


def unpublish_routine(routine: Routine) -> Routine:
    routine.is_public = False
    routine.save(update_fields=['is_public', 'updated_at'])
    return routine


def ensure_share_code(routine: Routine) -> str:
    if routine.share_code:
        return routine.share_code
    routine.share_code = generate_share_code()
    routine.save(update_fields=['share_code', 'updated_at'])
    return routine.share_code
