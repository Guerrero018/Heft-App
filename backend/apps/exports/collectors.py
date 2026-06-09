from __future__ import annotations

from collections import defaultdict

from django.db.models import QuerySet

from apps.users.models import BodyMeasures
from apps.workouts.models import WorkoutSession, WorkoutSet

from .filters import ExportFilters, ExportPreview


def _apply_workout_filters(qs: QuerySet, filters: ExportFilters) -> QuerySet:
    if filters.date_from:
        qs = qs.filter(date__gte=filters.date_from)
    if filters.date_to:
        qs = qs.filter(date__lte=filters.date_to)
    if filters.routine_id:
        qs = qs.filter(routine_id=filters.routine_id)
    if filters.exercise_id:
        qs = qs.filter(sets__exercise_id=filters.exercise_id).distinct()
    return qs


def fetch_workouts(user, filters: ExportFilters) -> list[WorkoutSession]:
    qs = (
        WorkoutSession.objects.filter(user=user, is_completed=True)
        .prefetch_related('sets__exercise', 'routine')
        .order_by('-date', '-start_time')
    )
    qs = _apply_workout_filters(qs, filters)
    return list(qs)


def fetch_body_measures(user, filters: ExportFilters) -> list[BodyMeasures]:
    qs = BodyMeasures.objects.filter(user=user).order_by('-date')
    if filters.date_from:
        qs = qs.filter(date__gte=filters.date_from)
    if filters.date_to:
        qs = qs.filter(date__lte=filters.date_to)
    return list(qs)


def fetch_prs(user, filters: ExportFilters) -> list[dict]:
    sets_qs = WorkoutSet.objects.filter(
        workout_session__user=user,
        workout_session__is_completed=True,
        is_completed=True,
    ).select_related('exercise', 'workout_session', 'workout_session__routine')

    if filters.date_from:
        sets_qs = sets_qs.filter(workout_session__date__gte=filters.date_from)
    if filters.date_to:
        sets_qs = sets_qs.filter(workout_session__date__lte=filters.date_to)
    if filters.routine_id:
        sets_qs = sets_qs.filter(workout_session__routine_id=filters.routine_id)
    if filters.exercise_id:
        sets_qs = sets_qs.filter(exercise_id=filters.exercise_id)

    by_exercise: dict[int, list[WorkoutSet]] = defaultdict(list)
    for workout_set in sets_qs:
        by_exercise[workout_set.exercise_id].append(workout_set)

    prs: list[dict] = []
    for exercise_sets in by_exercise.values():
        best = max(exercise_sets, key=lambda s: (s.weight, s.reps))
        session = best.workout_session
        prs.append(
            {
                'exercise_id': best.exercise_id,
                'exercise_name': best.exercise.name,
                'muscle_group': best.exercise.muscle_group,
                'max_weight_kg': best.weight,
                'reps': best.reps,
                'date': session.date.isoformat(),
                'workout_name': session.name or 'Entrenamiento',
                'routine_name': session.routine.name if session.routine else '',
            },
        )

    prs.sort(key=lambda row: row['exercise_name'].lower())
    return prs


def build_preview(user, filters: ExportFilters) -> ExportPreview:
    workouts = fetch_workouts(user, filters) if filters.include_workouts else []
    measures = fetch_body_measures(user, filters) if filters.include_body_measures else []
    prs = fetch_prs(user, filters) if filters.include_prs else []
    return ExportPreview(
        workouts_count=len(workouts),
        body_measures_count=len(measures),
        prs_count=len(prs),
    )


def collect_export_data(user, filters: ExportFilters) -> dict:
    return {
        'workouts': fetch_workouts(user, filters) if filters.include_workouts else [],
        'body_measures': fetch_body_measures(user, filters)
        if filters.include_body_measures
        else [],
        'prs': fetch_prs(user, filters) if filters.include_prs else [],
        'filters_summary': _filters_summary(filters),
        'generated_for': user.username,
    }


def _filters_summary(filters: ExportFilters) -> str:
    parts: list[str] = []
    if filters.date_from:
        parts.append(f'desde {filters.date_from.isoformat()}')
    if filters.date_to:
        parts.append(f'hasta {filters.date_to.isoformat()}')
    if filters.routine_id:
        parts.append(f'rutina #{filters.routine_id}')
    if filters.exercise_id:
        parts.append(f'ejercicio #{filters.exercise_id}')
    return ', '.join(parts) if parts else 'Sin filtros adicionales'
