"""Celery tasks for push notifications.

All tasks are periodic and scheduled via Celery Beat.  Each task:
  1. Queries eligible users (preferences enabled + active device tokens).
  2. Skips users that already received the same notification today (dedup_key).
  3. Sends via Firebase Admin multicast in batches.
  4. Writes a NotificationLog entry per user per attempt.
"""

import logging
from datetime import date, timedelta

from celery import shared_task
from django.db.models import Max
from django.utils import timezone

from .firebase import send_push
from .models import DeviceToken, NotificationLog, UserNotificationPreferences

logger = logging.getLogger(__name__)

# Maximum FCM tokens per multicast call
MULTICAST_BATCH = 500


def _active_tokens_for_user(user_id: int) -> list[str]:
    return list(
        DeviceToken.objects.filter(user_id=user_id, is_active=True).values_list(
            "token", flat=True
        )
    )


def _already_sent_today(user_id: int, notif_type: str) -> bool:
    dedup = str(date.today())
    return NotificationLog.objects.filter(
        user_id=user_id,
        notification_type=notif_type,
        dedup_key=dedup,
        status="sent",
    ).exists()


def _log(user_id, token_obj, notif_type, title, body, success, error=""):
    NotificationLog.objects.create(
        user_id=user_id,
        device_token=token_obj,
        notification_type=notif_type,
        status="sent" if success else "failed",
        title=title,
        body=body,
        error_message=error,
        dedup_key=str(date.today()),
    )


def _send_to_user(user_id, notif_type, title, body):
    """Send notification to all active devices of a user and log results."""
    tokens_qs = DeviceToken.objects.filter(user_id=user_id, is_active=True)
    for token_obj in tokens_qs:
        success = send_push(token=token_obj.token, title=title, body=body)
        if success:
            token_obj.last_used_at = timezone.now()
            token_obj.save(update_fields=["last_used_at"])
        _log(user_id, token_obj, notif_type, title, body, success)


# ---------------------------------------------------------------------------
# Workout reminder
# ---------------------------------------------------------------------------

@shared_task(name="notifications.send_workout_reminders")
def send_workout_reminders():
    """Sent every hour by Beat; fires for users whose workout reminder hour matches now (UTC)."""
    now = timezone.now()
    current_hour = now.hour
    current_day = now.weekday()  # 0=Monday … 6=Sunday

    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        workout_enabled=True,
        workout_hour=current_hour,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        if current_day not in (prefs.workout_days or []):
            continue
        if _already_sent_today(prefs.user_id, "workout_reminder"):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        title = "Hora de entrenar 💪"
        body = "Tu sesión de hoy te espera. ¡Vamos a ello!"
        _send_to_user(prefs.user_id, "workout_reminder", title, body)
        count += 1

    logger.info("Workout reminders sent: %d", count)
    return count


# ---------------------------------------------------------------------------
# Body progress reminder
# ---------------------------------------------------------------------------

@shared_task(name="notifications.send_body_progress_reminders")
def send_body_progress_reminders():
    """Run daily; checks frequency + day to decide who should receive."""
    now = timezone.now()
    current_day = now.weekday()
    current_hour = now.hour

    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        body_progress_enabled=True,
        body_progress_day_of_week=current_day,
        body_progress_hour=current_hour,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        if _already_sent_today(prefs.user_id, "body_progress"):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        # For biweekly/monthly frequency, check last log date
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
        _send_to_user(prefs.user_id, "body_progress", title, body)
        count += 1

    logger.info("Body progress reminders sent: %d", count)
    return count


# ---------------------------------------------------------------------------
# Weekly summary
# ---------------------------------------------------------------------------

@shared_task(name="notifications.send_weekly_summaries")
def send_weekly_summaries():
    """Run hourly; fires on the configured day + hour."""
    now = timezone.now()
    current_day = now.weekday()
    current_hour = now.hour

    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        weekly_summary_enabled=True,
        weekly_summary_day_of_week=current_day,
        weekly_summary_hour=current_hour,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        if _already_sent_today(prefs.user_id, "weekly_summary"):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        # Count sessions this week
        week_start = timezone.now() - timedelta(days=7)
        from apps.workouts.models import WorkoutSession
        sessions = WorkoutSession.objects.filter(
            user_id=prefs.user_id,
            date__gte=week_start.date(),
            is_completed=True,
        ).count()

        title = "Tu resumen semanal 🏆"
        if sessions > 0:
            body = f"¡Completaste {sessions} entrenamiento{'s' if sessions != 1 else ''} esta semana! Revisa tu progreso."
        else:
            body = "Esta semana aún no has entrenado. ¡Empieza la próxima con fuerza!"

        _send_to_user(prefs.user_id, "weekly_summary", title, body)
        count += 1

    logger.info("Weekly summaries sent: %d", count)
    return count


# ---------------------------------------------------------------------------
# Inactivity alert
# ---------------------------------------------------------------------------

@shared_task(name="notifications.send_inactivity_alerts")
def send_inactivity_alerts():
    """Run daily at a fixed hour; checks users who haven't trained in N days."""
    from apps.workouts.models import WorkoutSession
    from django.contrib.auth import get_user_model

    User = get_user_model()

    prefs_qs = UserNotificationPreferences.objects.filter(
        all_enabled=True,
        inactivity_enabled=True,
    ).select_related("user")

    count = 0
    for prefs in prefs_qs:
        if _already_sent_today(prefs.user_id, "inactivity"):
            continue
        if not _active_tokens_for_user(prefs.user_id):
            continue

        threshold_date = (timezone.now() - timedelta(days=prefs.inactivity_threshold_days)).date()
        has_recent_session = WorkoutSession.objects.filter(
            user_id=prefs.user_id,
            date__gte=threshold_date,
            is_completed=True,
        ).exists()

        if has_recent_session:
            continue

        title = "¡Te echamos de menos! 🔥"
        body = (
            f"Llevas {prefs.inactivity_threshold_days} días sin entrenar. "
            "¡Vuelve al gym y retoma tu racha!"
        )
        _send_to_user(prefs.user_id, "inactivity", title, body)
        count += 1

    logger.info("Inactivity alerts sent: %d", count)
    return count
