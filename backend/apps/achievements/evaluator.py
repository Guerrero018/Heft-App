from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import date, datetime, timedelta
from typing import Any

from django.utils import timezone

from apps.exercises.models import Exercise
from apps.routines.models import Routine
from apps.statistics.services import _all_streak_session_dates, _compute_week_streak, _week_start_monday
from apps.users.models import BodyMeasurePhoto, BodyMeasures
from apps.workouts.models import WorkoutSession, WorkoutSet

from .exercise_matcher import is_bodyweight_key, matches_strength_exercise
from .models import Achievement


@dataclass
class EvaluatedAchievement:
    is_unlocked: bool
    progress: float
    progress_label: str
    unlocked_at: datetime | None


def _set_counts_weight(set_obj: WorkoutSet) -> bool:
    return set_obj.is_completed and set_obj.weight > 0 and set_obj.reps > 0


def _set_counts_bodyweight(set_obj: WorkoutSet) -> bool:
    return set_obj.is_completed and set_obj.reps > 0


def _load_context(user) -> dict[str, Any]:
    sessions = list(
        WorkoutSession.objects.filter(user=user)
        .prefetch_related("sets__exercise")
        .order_by("date", "start_time")
    )
    valid_sessions = [
        s
        for s in sessions
        if any(_set_counts_weight(st) or _set_counts_bodyweight(st) for st in s.sets.all())
    ]

    muscle_by_id = dict(Exercise.objects.values_list("id", "muscle_group"))

    body_entries = BodyMeasures.objects.filter(user=user).count()
    photo_count = BodyMeasurePhoto.objects.filter(
        body_measure__user=user
    ).count()
    routine_count = Routine.objects.filter(user=user).count()
    custom_exercises = Exercise.objects.filter(is_global=False, user=user).count()

    return {
        "sessions": valid_sessions,
        "muscle_by_id": muscle_by_id,
        "body_entries": body_entries,
        "photo_count": photo_count,
        "routine_count": routine_count,
        "custom_exercises": custom_exercises,
        "week_streak": _compute_week_streak(
            _all_streak_session_dates(user),
            user.workout_days_per_week or 3,
        ),
        "user": user,
    }


def _distinct_days(sessions: list[WorkoutSession]) -> int:
    return len({s.date for s in sessions})


def _total_sets(sessions: list[WorkoutSession]) -> int:
    count = 0
    for session in sessions:
        for st in session.sets.all():
            if _set_counts_weight(st) or _set_counts_bodyweight(st):
                count += 1
    return count


def _total_volume(sessions: list[WorkoutSession]) -> float:
    total = 0.0
    for session in sessions:
        for st in session.sets.all():
            if _set_counts_weight(st):
                total += st.weight * st.reps
    return total


def _max_weight(sessions: list[WorkoutSession], exercise_key: str) -> float:
    best = 0.0
    for session in sessions:
        for st in session.sets.all():
            if not _set_counts_weight(st):
                continue
            if matches_strength_exercise(st.exercise.name, exercise_key):
                best = max(best, st.weight)
    return best


def _max_reps(sessions: list[WorkoutSession], exercise_key: str) -> int:
    best = 0
    for session in sessions:
        for st in session.sets.all():
            if not _set_counts_bodyweight(st):
                continue
            if matches_strength_exercise(st.exercise.name, exercise_key):
                best = max(best, st.reps)
    return best


def _strength_unlocked(sessions, exercise_key: str, threshold: float, reps: bool) -> bool:
    if reps or is_bodyweight_key(exercise_key):
        return _max_reps(sessions, exercise_key) >= threshold
    return _max_weight(sessions, exercise_key) >= threshold


def _estimate_strength_unlock_at(
    sessions: list[WorkoutSession],
    exercise_key: str,
    threshold: float,
    reps: bool,
) -> datetime | None:
    for session in sessions:
        for st in session.sets.all():
            if reps or is_bodyweight_key(exercise_key):
                if (
                    _set_counts_bodyweight(st)
                    and matches_strength_exercise(st.exercise.name, exercise_key)
                    and st.reps >= threshold
                ):
                    return timezone.make_aware(
                        datetime.combine(session.date, datetime.min.time())
                    )
            elif (
                _set_counts_weight(st)
                and matches_strength_exercise(st.exercise.name, exercise_key)
                and st.weight >= threshold
            ):
                return timezone.make_aware(
                    datetime.combine(session.date, datetime.min.time())
                )
    return None


def _exercises_with_pr(sessions: list[WorkoutSession]) -> set[int]:
    max_by_exercise: dict[int, float] = {}
    pr_exercises: set[int] = set()
    for session in sessions:
        for st in session.sets.all():
            if _set_counts_weight(st):
                value = st.weight
            elif _set_counts_bodyweight(st):
                value = float(st.reps)
            else:
                continue
            prev = max_by_exercise.get(st.exercise_id)
            if prev is not None and value > prev:
                pr_exercises.add(st.exercise_id)
            current = max_by_exercise.get(st.exercise_id)
            if current is None or value > current:
                max_by_exercise[st.exercise_id] = value
    return pr_exercises


def _has_progress_10pct(sessions: list[WorkoutSession]) -> bool:
    today = timezone.localdate()
    last_30_start = today - timedelta(days=29)
    prev_30_start = today - timedelta(days=59)
    prev_30_end = today - timedelta(days=30)

    max_recent: dict[int, float] = {}
    max_previous: dict[int, float] = {}

    for session in sessions:
        day = session.date
        for st in session.sets.all():
            if not _set_counts_weight(st):
                continue
            value = st.weight
            if day >= last_30_start:
                max_recent[st.exercise_id] = max(
                    max_recent.get(st.exercise_id, 0), value
                )
            elif prev_30_start <= day <= prev_30_end:
                max_previous[st.exercise_id] = max(
                    max_previous.get(st.exercise_id, 0), value
                )

    for ex_id, recent in max_recent.items():
        previous = max_previous.get(ex_id)
        if previous and previous > 0 and recent >= previous * 1.1:
            return True
    return False


def _has_full_body_week(sessions, muscle_by_id: dict[int, str]) -> bool:
    weeks: dict[date, set[str]] = defaultdict(set)
    for session in sessions:
        week_start = _week_start_monday(session.date)
        for st in session.sets.all():
            if not (_set_counts_weight(st) or _set_counts_bodyweight(st)):
                continue
            muscle = muscle_by_id.get(st.exercise_id)
            if muscle:
                weeks[week_start].add(muscle)

    for muscles in weeks.values():
        has_leg = any(m in muscles for m in ("cuadriceps", "gluteos", "isquiotibiales"))
        if (
            "pecho" in muscles
            and "espalda" in muscles
            and has_leg
            and "hombros" in muscles
        ):
            return True
    return False


def _year_active(sessions: list[WorkoutSession]) -> bool:
    if len(sessions) < 12:
        return False
    first = sessions[0].date
    if (timezone.localdate() - first).days < 365:
        return False
    months = {f"{s.date.year}-{s.date.month}" for s in sessions}
    return len(months) >= 12


def _has_profile_photo(user) -> bool:
    if not user.profile_picture:
        return False
    url = str(user.profile_picture)
    return "DefaultProfile" not in url


def evaluate_achievement(achievement: Achievement, ctx: dict[str, Any]) -> EvaluatedAchievement:
    sessions: list[WorkoutSession] = ctx["sessions"]
    criteria = achievement.criteria or {}
    ctype = criteria.get("type", "")
    user = ctx["user"]

    unlocked = False
    progress = 0.0
    progress_label = ""
    unlocked_at = None

    if ctype == "strength_weight":
        key = criteria["exercise_key"]
        threshold = float(criteria["threshold"])
        current = _max_weight(sessions, key)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        if current > 0:
            progress_label = f"{current:g} / {threshold:g} kg"
        if unlocked:
            unlocked_at = _estimate_strength_unlock_at(sessions, key, threshold, False)

    elif ctype == "strength_reps":
        key = criteria["exercise_key"]
        threshold = int(criteria["threshold"])
        current = _max_reps(sessions, key)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        if current > 0:
            progress_label = f"{current} / {threshold} reps"
        if unlocked:
            unlocked_at = _estimate_strength_unlock_at(
                sessions, key, float(threshold), True
            )

    elif ctype == "week_streak":
        threshold = int(criteria["threshold"])
        current = ctx["week_streak"]
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold} sem"

    elif ctype == "distinct_workout_days":
        threshold = int(criteria["threshold"])
        current = _distinct_days(sessions)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold} días"

    elif ctype == "year_active":
        unlocked = _year_active(sessions)
        progress = 1.0 if unlocked else min(1.0, len(sessions) / 12)

    elif ctype == "total_sessions":
        threshold = int(criteria["threshold"])
        current = len(sessions)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "total_sets":
        threshold = int(criteria["threshold"])
        current = _total_sets(sessions)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "total_volume_kg":
        threshold = float(criteria["threshold"])
        current = _total_volume(sessions)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current / 1000:.0f}k / {threshold / 1000:.0f}k kg"

    elif ctype == "session_duration_min":
        threshold = int(criteria["threshold"])
        for session in sessions:
            if session.end_time and session.start_time:
                minutes = (session.end_time - session.start_time).total_seconds() / 60
                if minutes >= threshold:
                    unlocked = True
                    break
        progress = 1.0 if unlocked else 0.0

    elif ctype == "pr_any":
        prs = _exercises_with_pr(sessions)
        unlocked = len(prs) > 0
        progress = 1.0 if unlocked else 0.0

    elif ctype == "pr_exercise_count":
        threshold = int(criteria["threshold"])
        prs = _exercises_with_pr(sessions)
        current = len(prs)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "pr_big3":
        big3 = [
            _strength_unlocked(sessions, "bench_press", 60, False),
            _strength_unlocked(sessions, "squat", 80, False),
            _strength_unlocked(sessions, "deadlift", 100, False),
        ]
        count = sum(1 for x in big3 if x)
        unlocked = all(big3)
        progress = count / 3
        progress_label = f"{count} / 3"

    elif ctype == "progress_10pct":
        unlocked = _has_progress_10pct(sessions)
        progress = 1.0 if unlocked else 0.0

    elif ctype == "body_entries":
        threshold = int(criteria["threshold"])
        current = ctx["body_entries"]
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "body_photos":
        threshold = int(criteria["threshold"])
        current = ctx["photo_count"]
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "routines_count":
        threshold = int(criteria["threshold"])
        current = ctx["routine_count"]
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "distinct_exercises":
        threshold = int(criteria["threshold"])
        ids = set()
        for session in sessions:
            for st in session.sets.all():
                if _set_counts_weight(st) or _set_counts_bodyweight(st):
                    ids.add(st.exercise_id)
        current = len(ids)
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "custom_exercises":
        threshold = int(criteria["threshold"])
        current = ctx["custom_exercises"]
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0

    elif ctype == "onboarding":
        unlocked = bool(user.is_onboarded)
        progress = 1.0 if unlocked else 0.0

    elif ctype == "profile_photo":
        unlocked = _has_profile_photo(user)
        progress = 1.0 if unlocked else 0.0

    elif ctype == "night_workout":
        unlocked = any(
            s.start_time.hour >= 22 for s in sessions if s.start_time
        )
        progress = 1.0 if unlocked else 0.0

    elif ctype == "early_workout":
        unlocked = any(s.start_time.hour < 7 for s in sessions if s.start_time)
        progress = 1.0 if unlocked else 0.0

    elif ctype == "weekend_sessions":
        threshold = int(criteria["threshold"])
        current = sum(
            1
            for s in sessions
            if s.date.weekday() >= 5  # Saturday=5, Sunday=6
        )
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "full_body_week":
        unlocked = _has_full_body_week(sessions, ctx["muscle_by_id"])
        progress = 1.0 if unlocked else 0.0

    elif ctype == "rpe_sets":
        threshold = int(criteria["threshold"])
        current = sum(
            1
            for session in sessions
            for st in session.sets.all()
            if _set_counts_weight(st) and st.rpe is not None
        )
        unlocked = current >= threshold
        progress = min(1.0, current / threshold) if threshold > 0 else 0.0
        progress_label = f"{current} / {threshold}"

    elif ctype == "comeback":
        gap = int(criteria.get("gap_days", 14))
        if len(sessions) >= 2:
            for i in range(1, len(sessions)):
                delta = (sessions[i].date - sessions[i - 1].date).days
                if delta >= gap:
                    unlocked = True
                    break
        progress = 1.0 if unlocked else 0.0

    return EvaluatedAchievement(
        is_unlocked=unlocked,
        progress=progress,
        progress_label=progress_label,
        unlocked_at=unlocked_at,
    )
