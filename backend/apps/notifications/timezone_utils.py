"""Zona horaria local del usuario para recordatorios programados."""

from zoneinfo import ZoneInfo

from django.utils import timezone

DEFAULT_TIMEZONE = "Europe/Madrid"

# Hora local del día en la que se evalúa inactividad (cron horario).
INACTIVITY_LOCAL_HOUR = 10


def resolve_zone(tz_name: str | None) -> ZoneInfo:
    name = (tz_name or "").strip() or DEFAULT_TIMEZONE
    try:
        return ZoneInfo(name)
    except Exception:
        try:
            return ZoneInfo("UTC")
        except Exception:
            return ZoneInfo("Etc/UTC")


def user_local_now(tz_name: str | None):
    """Hora actual en la zona IANA del usuario (p. ej. Europe/Madrid)."""
    return timezone.now().astimezone(resolve_zone(tz_name))
