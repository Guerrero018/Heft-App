from collections import defaultdict
from datetime import date, datetime, timedelta
from typing import Any

from django.utils import timezone

from apps.workouts.models import WorkoutSession, WorkoutSet

PERIOD_DAYS = {
    "week": 7,
    "calendar_week": 7,
    "month": 30,
    "3months": 90,
    "year": 365,
    "all": None,
}

PERIOD_LABELS = {
    "week": "Semana",
    "month": "Mes",
    "3months": "3 Meses",
    "year": "Año",
    "all": "Todo",
}

# Claves del mapa corporal en el frontend -> grupos musculares del API
MUSCLE_MAP_KEYS = {
    "pecho": ("chest", "front"),
    "abdominales": ("abs", "front"),
    "espalda_baja": ("abs", "front"),
    "cuadriceps": ("quads", "front"),
    "hombros": ("shoulders", "front"),
    "trapecios": ("traps", "back"),
    "biceps": ("biceps", "front"),
    "espalda": ("back", "back"),
    "triceps": ("triceps", "back"),
    "gluteos": ("glutes", "back"),
    "isquiotibiales": ("hamstrings", "back"),
    "gemelos": ("calves", "back"),
    "aductores": ("adductors", "front"),
    "abductores": ("hip_abductors", "front"),
    "antebrazos": ("forearms", "front"),
    "cardio": ("abs", "front"),
    "otros": ("abs", "front"),
}

MUSCLE_GROUP_LABELS = dict(
    [
        ("pecho", "Pecho"),
        ("espalda", "Espalda"),
        ("hombros", "Hombros"),
        ("cuadriceps", "Cuádriceps"),
        ("biceps", "Bíceps"),
        ("triceps", "Tríceps"),
        ("abdominales", "Abs"),
        ("gluteos", "Glúteos"),
        ("gemelos", "Gemelos"),
        ("isquiotibiales", "Isquios"),
        ("trapecios", "Hombros"),
        ("cardio", "Cardio"),
        ("otros", "Otros"),
    ]
)


def _resolve_period(period: str) -> tuple[str, datetime | None, datetime]:
    key = period if period in PERIOD_DAYS else "week"
    end = timezone.now()
    days = PERIOD_DAYS[key]
    start = None if days is None else end - timedelta(days=days)
    return key, start, end


def _period_date_bounds(period_key: str) -> tuple[date | None, date]:
    """Rango inclusivo por fecha de sesión (alineado con el historial)."""
    today = timezone.localdate()
    if period_key == "calendar_week":
        start = _week_start_monday(today)
        return start, start + timedelta(days=6)
    days = PERIOD_DAYS[period_key]
    if days is None:
        return None, today
    start = today - timedelta(days=days - 1)
    return start, today


def _sessions_queryset(user, start_date: date | None, end_date: date):
    qs = WorkoutSession.objects.filter(user=user, is_completed=True)
    if start_date is not None:
        qs = qs.filter(date__gte=start_date)
    return qs.filter(date__lte=end_date)


def _sets_queryset(user, start_date: date | None, end_date: date):
    qs = (
        WorkoutSet.objects.filter(
            workout_session__user=user,
            weight__gt=0,
            reps__gt=0,
        )
        .select_related("exercise", "workout_session")
    )
    if start_date is not None:
        qs = qs.filter(workout_session__date__gte=start_date)
    return qs.filter(workout_session__date__lte=end_date)


def _week_start_monday(d: date) -> date:
    return d - timedelta(days=d.weekday())


def _compute_week_streak(session_dates: list, target_days_per_week: int) -> int:
    """Semanas consecutivas cumpliendo el objetivo semanal de días de entreno."""
    target = max(1, min(7, int(target_days_per_week or 1)))

    days_by_week: dict[date, set[date]] = defaultdict(set)
    for raw in session_dates:
        if raw is None:
            continue
        day = raw if isinstance(raw, date) else raw.date()
        week_start = _week_start_monday(day)
        days_by_week[week_start].add(day)

    today = timezone.localdate()
    current_week_start = _week_start_monday(today)
    current_count = len(days_by_week.get(current_week_start, ()))
    days_remaining = 7 - today.weekday()
    still_achievable = current_count + days_remaining >= target

    streak = 0
    week_start = current_week_start
    for _ in range(520):
        count = len(days_by_week.get(week_start, ()))
        is_current_week = week_start == current_week_start

        if count >= target:
            streak += 1
        elif is_current_week and still_achievable:
            pass
        else:
            break

        week_start -= timedelta(days=7)

    return streak


def _all_streak_session_dates(user) -> list:
    """Días con sesión completada y al menos una serie válida (histórico completo)."""
    session_ids = (
        WorkoutSet.objects.filter(
            workout_session__user=user,
            weight__gt=0,
            reps__gt=0,
        )
        .values_list("workout_session_id", flat=True)
        .distinct()
    )
    return list(
        WorkoutSession.objects.filter(
            user=user,
            is_completed=True,
            id__in=session_ids,
        ).values_list("date", flat=True)
    )


def build_user_statistics(user, period: str = "week") -> dict[str, Any]:
    period_key, _, _ = _resolve_period(period)
    start_date, end_date = _period_date_bounds(period_key)
    sets_qs = _sets_queryset(user, start_date, end_date)

    session_ids_with_sets = set(
        sets_qs.values_list("workout_session_id", flat=True).distinct()
    )
    sessions_qs = _sessions_queryset(user, start_date, end_date).filter(
        id__in=session_ids_with_sets
    )

    session_list = list(sessions_qs)
    session_dates = [s.date for s in session_list if s.date]

    total_volume = 0.0
    total_sets = 0
    volume_by_muscle: dict[str, float] = defaultdict(float)
    volume_by_day: dict[str, float] = defaultdict(float)

    exercise_sessions: dict[int, dict[str, Any]] = defaultdict(
        lambda: {
            "exercise_id": 0,
            "exercise_name": "",
            "muscle_group": "",
            "points": [],
            "total_volume": 0.0,
        }
    )

    for workout_set in sets_qs.iterator():
        volume = float(workout_set.weight) * workout_set.reps
        total_volume += volume
        total_sets += 1

        muscle = workout_set.exercise.muscle_group or "otros"
        volume_by_muscle[muscle] += volume

        session = workout_set.workout_session
        day_key = session.date.isoformat() if session.date else session.start_time.date().isoformat()
        volume_by_day[day_key] += volume

        ex_id = workout_set.exercise_id
        entry = exercise_sessions[ex_id]
        entry["exercise_id"] = ex_id
        entry["exercise_name"] = workout_set.exercise.name
        entry["muscle_group"] = muscle
        entry["total_volume"] += volume

        session_key = session.start_time.isoformat()
        points_map = {p["session_at"]: p for p in entry["points"]}
        if session_key not in points_map:
            points_map[session_key] = {
                "session_at": session_key,
                "date": day_key,
                "max_weight": 0.0,
                "volume": 0.0,
            }
        point = points_map[session_key]
        point["max_weight"] = max(point["max_weight"], float(workout_set.weight))
        point["volume"] += volume
        entry["points"] = sorted(points_map.values(), key=lambda p: p["session_at"])

    # Adherencia: días con entreno vs objetivo semanal
    days_in_period = PERIOD_DAYS[period_key] or max(
        (end_date - min(session_dates)).days + 1 if session_dates else 1,
        1,
    )
    weeks_in_period = max(days_in_period / 7.0, 1.0)
    expected_sessions = int(round(user.workout_days_per_week * weeks_in_period))
    workout_days = len(set(session_dates))
    adherence_percent = (
        min(100, round((workout_days / expected_sessions) * 100))
        if expected_sessions > 0
        else (100 if workout_days > 0 else 0)
    )

    # Distribución muscular normalizada (0-1) para mapa
    max_muscle_vol = max(volume_by_muscle.values()) if volume_by_muscle else 0.0
    front_loads: dict[str, float] = defaultdict(float)
    back_loads: dict[str, float] = defaultdict(float)

    for muscle, vol in volume_by_muscle.items():
        normalized = round(vol / max_muscle_vol, 2) if max_muscle_vol > 0 else 0.0
        map_key, side = MUSCLE_MAP_KEYS.get(muscle, ("abs", "front"))
        if side == "back":
            back_loads[map_key] = max(back_loads[map_key], normalized)
        else:
            front_loads[map_key] = max(front_loads[map_key], normalized)

    # Top ejercicios por volumen (máx 6)
    top_exercises = sorted(
        exercise_sessions.values(),
        key=lambda e: e["total_volume"],
        reverse=True,
    )[:6]

    exercise_progress = []
    for ex in top_exercises:
        points = ex["points"]
        volume_trend = 0.0
        max_weight_trend = 0.0
        if len(points) >= 2:
            first_v = points[0]["volume"]
            last_v = points[-1]["volume"]
            if first_v > 0:
                volume_trend = round(((last_v - first_v) / first_v) * 100, 1)
            first_w = points[0]["max_weight"]
            last_w = points[-1]["max_weight"]
            if first_w > 0:
                max_weight_trend = round(((last_w - first_w) / first_w) * 100, 1)

        exercise_progress.append(
            {
                "exercise_id": ex["exercise_id"],
                "exercise_name": ex["exercise_name"],
                "muscle_group": ex["muscle_group"],
                "muscle_group_label": MUSCLE_GROUP_LABELS.get(
                    ex["muscle_group"], ex["muscle_group"]
                ),
                "trend_percent": volume_trend,
                "volume_trend_percent": volume_trend,
                "max_weight_trend_percent": max_weight_trend,
                "data_points": [
                    {
                        "date": p["date"],
                        "max_weight": round(p["max_weight"], 1),
                        "volume": round(p["volume"], 1),
                    }
                    for p in points
                ],
            }
        )

    volume_by_muscle_sorted = sorted(
        volume_by_muscle.items(), key=lambda x: x[1], reverse=True
    )[:8]

    volume_by_muscle_group = [
        {
            "muscle_group": mg,
            "label": MUSCLE_GROUP_LABELS.get(mg, mg.replace("_", " ").title()),
            "volume": round(vol, 1),
        }
        for mg, vol in volume_by_muscle_sorted
    ]

    # Volumen por día (últimos 7 días del periodo o todos los días con datos)
    sorted_days = sorted(volume_by_day.keys())
    if period_key == "week" or len(sorted_days) <= 7:
        day_keys = sorted_days[-7:]
    else:
        # Muestrear hasta 7 puntos distribuidos
        step = max(len(sorted_days) // 7, 1)
        day_keys = sorted_days[::step][:7]

    daily_volume = [
        {
            "date": d,
            "label": date.fromisoformat(d).strftime("%d/%m") if d else "",
            "volume": round(volume_by_day[d], 1),
        }
        for d in day_keys
    ]

    period_start_str = start_date.isoformat() if start_date else None
    period_end_str = end_date.isoformat()

    return {
        "period": period_key,
        "period_label": PERIOD_LABELS[period_key],
        "period_start": period_start_str,
        "period_end": period_end_str,
        "summary": {
            "total_workouts": len(session_list),
            "total_volume_kg": round(total_volume, 1),
            "total_sets": total_sets,
            "workout_days": workout_days,
            "expected_workout_days": expected_sessions,
            "adherence_percent": adherence_percent,
            "streak_days": _compute_week_streak(
                _all_streak_session_dates(user),
                user.workout_days_per_week,
            ),
        },
        "daily_volume": daily_volume,
        "volume_by_muscle_group": volume_by_muscle_group,
        "muscle_map": {
            "front": dict(front_loads),
            "back": dict(back_loads),
        },
        "exercise_progress": exercise_progress,
    }
