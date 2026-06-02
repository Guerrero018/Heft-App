"""Ejecución de recordatorios programados sin Celery (p. ej. cron-job.org → HTTP)."""

import logging

from django.conf import settings
from django.utils import timezone

from .tasks import (
    send_body_progress_reminders,
    send_inactivity_alerts,
    send_weekly_summaries,
    send_workout_reminders,
)

logger = logging.getLogger(__name__)

# Misma hora que CELERY_BEAT_SCHEDULE["inactivity-alerts-daily"] (UTC)
INACTIVITY_CRON_HOUR_UTC = 10


def run_scheduled_notification_jobs() -> dict[str, int]:
    """Ejecuta las mismas tareas que Celery Beat (síncrono)."""
    if not settings.NOTIFICATIONS_ENABLED:
        logger.info("NOTIFICATIONS_ENABLED=false — cron notifications skipped")
        return {
            "workout_reminder": 0,
            "body_progress": 0,
            "weekly_summary": 0,
            "inactivity": 0,
            "skipped": True,
        }

    results = {
        "workout_reminder": send_workout_reminders(),
        "body_progress": send_body_progress_reminders(),
        "weekly_summary": send_weekly_summaries(),
        "inactivity": 0,
    }

    if timezone.now().hour == INACTIVITY_CRON_HOUR_UTC:
        results["inactivity"] = send_inactivity_alerts()

    logger.info("Cron notifications finished: %s", results)
    return results
