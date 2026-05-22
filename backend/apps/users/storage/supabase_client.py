import os

from django.conf import settings

_client = None


def get_supabase_admin_client():
    """Cliente con service_role (solo backend, nunca en la app Flutter)."""
    global _client
    if _client is not None:
        return _client

    if not settings.SUPABASE_URL or not settings.SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError(
            "Faltan SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY en las variables de entorno."
        )

    from supabase import create_client

    _client = create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_ROLE_KEY)
    return _client


def is_supabase_configured() -> bool:
    return bool(
        os.getenv("SUPABASE_URL", getattr(settings, "SUPABASE_URL", ""))
        and os.getenv(
            "SUPABASE_SERVICE_ROLE_KEY",
            getattr(settings, "SUPABASE_SERVICE_ROLE_KEY", ""),
        )
    )
