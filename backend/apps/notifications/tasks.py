"""Tareas de envío de notificaciones push (Celery o cron HTTP)."""

import logging
from datetime import date, timedelta

from celery import shared_task
from django.utils import timezone

from .firebase import send_push
from .models import DeviceToken, NotificationLog, UserNotificationPreferences
from .timezone_utils import INACTIVITY_LOCAL_HOUR, user_local_now

logger = logging.getLogger(__name__)


def _active_tokens_for_user(user_id: int) -> list[str]:
    return list(
        DeviceToken.objects.filter(user_id=user_id, is_active=True).values_list(
            "token", flat=True
        )
    )


def _already_sent_today(
    user_id: int, notif_type: str, *, dedup_date: date | None = None
) -> bool:
    dedup = str(dedup_date or timezone.now().date())
    return NotificationLog.objects.filter(
        user_id=user_id,
        notification_type=notif_type,
        dedup_key=dedup,
        status="sent",
    ).exists()


def _log(
    user_id,
    token_obj,
    notif_type,
    title,
    body,
    success,
    error="",
    *,
    dedup_date: date | None = None,
):
    NotificationLog.objects.create(
        user_id=user_id,
        device_token=token_obj,
        notification_type=notif_type,
        status="sent" if success else "failed",
        title=title,
        body=body,
        error_message=error,
        dedup_key=str(dedup_date or timezone.now().date()),
    )


def _send_to_user(user_id, notif_type, title, body, *, dedup_date: date | None = None):
    """Send notification to all active devices of a user and log results."""
    tokens_qs = DeviceToken.objects.filter(user_id=user_id, is_active=True)
    for token_obj in tokens_qs:
        success = send_push(token=token_obj.token, title=title, body=body)
        if success:
            token_obj.last_used_at = timezone.now()
            token_obj.save(update_fields=["last_used_at"])
        _log(
            user_id,
            token_obj,
            notif_type,
            title,
            body,
            success,
            dedup_date=dedup_date,
        )


def _hour_matches(local_hour: int, target_hour: int) -> bool:
    """Cron horario (cada hora en :00): solo compara la hora local."""
    return local_hour == target_hour


def _body_measure_period_days(frequency: str) -> int:
    if frequency == "biweekly":
        return 14
    if frequency == "monthly":
        return 28
    return 7


def _has_recent_body_measure(user_id: int, reference_date: date, days: int) -> bool:
    from apps.users.models import BodyMeasures

    since = reference_date - timedelta(days=days)
    return BodyMeasures.objects.filter(user_id=user_id, date__gte=since).exists()


@shared_task(name="notifications.send_workout_reminders")
def send_workout_reminders():
    """Recordatorio de entrenamiento según hora local del usuario."""
    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        workout_enabled=True,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        local = user_local_now(prefs.timezone)
        today = local.date()
        if not _hour_matches(local.hour, prefs.workout_hour):
            continue
        if local.weekday() not in (prefs.workout_days or []):
            continue
        if _already_sent_today(prefs.user_id, "workout_reminder", dedup_date=today):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        title = "Hora de entrenar 💪"
        body = "Tu sesión de hoy te espera. ¡Vamos a ello!"
        _send_to_user(
            prefs.user_id, "workout_reminder", title, body, dedup_date=today
        )
        count += 1

    logger.info("Workout reminders sent: %d", count)
    return count


@shared_task(name="notifications.send_body_progress_reminders")
def send_body_progress_reminders():
    """Recordatorio de medidas según día y hora locales."""
    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        body_progress_enabled=True,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        local = user_local_now(prefs.timezone)
        today = local.date()
        if local.weekday() != prefs.body_progress_day_of_week:
            continue
        if not _hour_matches(local.hour, prefs.body_progress_hour):
            continue
        if _already_sent_today(prefs.user_id, "body_progress", dedup_date=today):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        period_days = _body_measure_period_days(prefs.body_progress_frequency)
        if _has_recent_body_measure(prefs.user_id, today, period_days):
            continue

        if prefs.body_progress_frequency != "weekly":
            days_threshold = 14 if prefs.body_progress_frequency == "biweekly" else 28
            last_sent = (
                NotificationLog.objects.filter(
                    user_id=prefs.user_id,
                    notification_type="body_progress",
                    status="sent",
                )
                .order_by("-sent_at")
                .values_list("sent_at", flat=True)
                .first()
            )
            if last_sent and (timezone.now() - last_sent).days < days_threshold:
                continue

        title = "Registra tu progreso corporal 📏"
        body = "Lleva el control de tu evolución. Añade tu peso y medidas de hoy."
        _send_to_user(prefs.user_id, "body_progress", title, body, dedup_date=today)
        count += 1

    logger.info("Body progress reminders sent: %d", count)
    return count


@shared_task(name="notifications.send_weekly_summaries")
def send_weekly_summaries():
    """Resumen semanal según día y hora locales."""
    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        weekly_summary_enabled=True,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        local = user_local_now(prefs.timezone)
        today = local.date()
        if local.weekday() != prefs.weekly_summary_day_of_week:
            continue
        if not _hour_matches(local.hour, prefs.weekly_summary_hour):
            continue
        if _already_sent_today(prefs.user_id, "weekly_summary", dedup_date=today):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        week_start = today - timedelta(days=7)
        from apps.workouts.models import WorkoutSession

        sessions = WorkoutSession.objects.filter(
            user_id=prefs.user_id,
            date__gte=week_start,
            date__lte=today,
            is_completed=True,
        ).count()

        title = "Tu resumen semanal 🏆"
        if sessions > 0:
            body = f"¡Completaste {sessions} entrenamiento{'s' if sessions != 1 else ''} esta semana! Revisa tu progreso."
        else:
            body = "Esta semana aún no has entrenado. ¡Empieza la próxima con fuerza!"

        _send_to_user(prefs.user_id, "weekly_summary", title, body, dedup_date=today)
        count += 1

    logger.info("Weekly summaries sent: %d", count)
    return count


def _days_since_last_workout(user_id: int, reference_date: date) -> int | None:
    """Días desde el último entrenamiento completado; None si nunca entrenó."""
    from apps.workouts.models import WorkoutSession

    last_session_date = (
        WorkoutSession.objects.filter(user_id=user_id, is_completed=True)
        .order_by("-date")
        .values_list("date", flat=True)
        .first()
    )
    if last_session_date is None:
        return None
    return (reference_date - last_session_date).days


def _inactivity_body(days_inactive: int | None) -> str:
    if days_inactive is None:
        return "Hace tiempo que no entrenas. ¡Vuelve al gym y retoma tu racha!"
    if days_inactive == 1:
        return "Llevas 1 día sin entrenar. ¡Vuelve al gym y retoma tu racha!"
    return (
        f"Llevas {days_inactive} días sin entrenar. "
        "¡Vuelve al gym y retoma tu racha!"
    )


@shared_task(name="notifications.send_inactivity_alerts")
def send_inactivity_alerts():
    """Alerta de inactividad a las 10:00 hora local de cada usuario."""
    from apps.workouts.models import WorkoutSession

    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        inactivity_enabled=True,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        local = user_local_now(prefs.timezone)
        if local.hour != INACTIVITY_LOCAL_HOUR:
            continue
        today = local.date()
        if _already_sent_today(prefs.user_id, "inactivity", dedup_date=today):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        threshold_date = today - timedelta(days=prefs.inactivity_threshold_days)
        has_recent_session = WorkoutSession.objects.filter(
            user_id=prefs.user_id,
            date__gte=threshold_date,
            is_completed=True,
        ).exists()

        if has_recent_session:
            continue

        days_inactive = _days_since_last_workout(prefs.user_id, today)
        title = "¡Te echamos de menos! 🔥"
        body = _inactivity_body(days_inactive)
        _send_to_user(prefs.user_id, "inactivity", title, body, dedup_date=today)
        count += 1

    logger.info("Inactivity alerts sent: %d", count)
    return count
