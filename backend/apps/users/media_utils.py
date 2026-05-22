from django.conf import settings

LEGACY_PROFILE_PREFIXES = ("profile_pics/",)
LEGACY_BODY_PREFIXES = ("body_measures/",)


def is_legacy_storage_path(name: str, *, field: str = "profile") -> bool:
    if not name:
        return False
    prefixes = (
        LEGACY_PROFILE_PREFIXES if field == "profile" else LEGACY_BODY_PREFIXES
    )
    return name.startswith(prefixes)


def resolve_media_url(file_field, request=None, *, legacy_kind="profile"):
    if not file_field or not file_field.name:
        return None

    name = file_field.name
    if name.startswith("http://") or name.startswith("https://"):
        return name.replace("http://", "https://", 1)

    storage = file_field.storage
    if settings.USE_SUPABASE_STORAGE:
        try:
            if is_legacy_storage_path(name, field=legacy_kind) or not storage.exists(name):
                return None
        except Exception:
            return None

    url = storage.url(name)
    if url.startswith("/media/"):
        if request:
            return request.build_absolute_uri(url)
        return f"http://10.0.2.2:8000{url}"
    if url.startswith("http://"):
        return url.replace("http://", "https://", 1)
    return url
