from __future__ import annotations

from dataclasses import dataclass, field

from django.db import transaction
from django.utils import timezone

from .evaluator import _load_context, evaluate_achievement
from .models import Achievement, UserAchievement


@dataclass
class SyncResult:
    records: list[UserAchievement] = field(default_factory=list)
    newly_unlocked: list[str] = field(default_factory=list)


def _achievement_queryset():
    return Achievement.objects.filter(is_active=True).order_by("sort_order", "slug")


def _user_records_queryset(user):
    return (
        UserAchievement.objects.filter(user=user)
        .select_related("achievement")
        .order_by("achievement__sort_order", "achievement__slug")
    )


@transaction.atomic
def sync_user_achievements(user) -> SyncResult:
    """Evalúa todos los logros activos y persiste el estado en UserAchievement."""
    previously_unlocked = set(
        UserAchievement.objects.filter(user=user, is_unlocked=True).values_list(
            "achievement__slug", flat=True
        )
    )

    ctx = _load_context(user)
    achievements = list(_achievement_queryset())
    existing_by_achievement_id = {
        ua.achievement_id: ua
        for ua in UserAchievement.objects.filter(user=user).select_related(
            "achievement"
        )
    }
    results: list[UserAchievement] = []
    newly_unlocked: list[str] = []

    for achievement in achievements:
        evaluated = evaluate_achievement(achievement, ctx)
        existing = existing_by_achievement_id.get(achievement.id)

        unlocked_at = evaluated.unlocked_at
        if evaluated.is_unlocked:
            if existing and existing.unlocked_at:
                unlocked_at = existing.unlocked_at
            elif unlocked_at is None:
                unlocked_at = timezone.now()
            if achievement.slug not in previously_unlocked:
                newly_unlocked.append(achievement.slug)
        else:
            unlocked_at = None

        record, _ = UserAchievement.objects.update_or_create(
            user=user,
            achievement=achievement,
            defaults={
                "is_unlocked": evaluated.is_unlocked,
                "progress": evaluated.progress,
                "progress_label": evaluated.progress_label or "",
                "unlocked_at": unlocked_at,
            },
        )
        results.append(record)

    return SyncResult(records=results, newly_unlocked=newly_unlocked)


def ensure_user_achievement_records(user) -> list[UserAchievement]:
    """
    Devuelve registros persistidos. Solo ejecuta sync completo si el usuario
    aún no tiene filas (primer acceso).
    """
    expected = _achievement_queryset().count()
    if UserAchievement.objects.filter(user=user).count() < expected:
        return sync_user_achievements(user).records
    return list(_user_records_queryset(user))


def build_achievements_read_payload(user) -> dict:
    records = ensure_user_achievement_records(user)
    total_count = _achievement_queryset().count()
    unlocked_count = sum(1 for record in records if record.is_unlocked)
    return {
        "unlocked_count": unlocked_count,
        "total_count": total_count,
        "achievements": records,
        "newly_unlocked": [],
    }


def build_achievements_sync_payload(user) -> dict:
    result = sync_user_achievements(user)
    total_count = _achievement_queryset().count()
    unlocked_count = sum(1 for record in result.records if record.is_unlocked)
    return {
        "unlocked_count": unlocked_count,
        "total_count": total_count,
        "achievements": result.records,
        "newly_unlocked": result.newly_unlocked,
    }
