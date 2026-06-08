from django.conf import settings

from apps.users.storage.supabase_client import get_supabase_admin_client, is_supabase_configured
from apps.users.storage.supabase_storage import SupabaseStorage


def ensure_achievements_bucket() -> None:
    """Crea el bucket de logros en Supabase si aún no existe."""
    if not is_supabase_configured():
        return

    bucket = settings.SUPABASE_ACHIEVEMENTS_BUCKET
    client = get_supabase_admin_client()
    existing = {item.name for item in client.storage.list_buckets()}
    if bucket in existing:
        return

    client.storage.create_bucket(
        bucket,
        options={"public": settings.SUPABASE_ACHIEVEMENTS_BUCKET_PUBLIC},
    )


class SupabaseAchievementStorage(SupabaseStorage):
    """Bucket público de insignias; rutas fijas por slug (sin UUID)."""

    def __init__(self):
        super().__init__(
            settings.SUPABASE_ACHIEVEMENTS_BUCKET,
            public=settings.SUPABASE_ACHIEVEMENTS_BUCKET_PUBLIC,
            signed_ttl_seconds=settings.SUPABASE_SIGNED_URL_TTL,
        )

    def get_available_name(self, name, max_length=None):
        return self._normalize_name(name)


def select_achievement_storage():
    if is_supabase_configured():
        return SupabaseAchievementStorage()
    from django.core.files.storage import FileSystemStorage

    return FileSystemStorage()


def achievement_image_upload_to(instance, filename: str) -> str:
    return f"{instance.slug}.png"
