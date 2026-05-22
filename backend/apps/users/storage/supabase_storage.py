import mimetypes
import uuid
from io import BytesIO

from django.conf import settings
from django.core.files.base import ContentFile
from django.core.files.storage import Storage
from django.utils.deconstruct import deconstructible

from .supabase_client import get_supabase_admin_client, is_supabase_configured


@deconstructible
class SupabaseStorage(Storage):
    """Almacenamiento en Supabase Storage vía API (service role en el servidor)."""

    def __init__(self, bucket_name, *, public=False, signed_ttl_seconds=3600):
        self.bucket_name = bucket_name
        self.public = public
        self.signed_ttl_seconds = signed_ttl_seconds

    def _client_bucket(self):
        return get_supabase_admin_client().storage.from_(self.bucket_name)

    def _normalize_name(self, name):
        return name.replace("\\", "/").lstrip("/")

    def get_available_name(self, name, max_length=None):
        name = self._normalize_name(name)
        base, ext = (name.rsplit(".", 1) + [""])[:2]
        if ext:
            ext = f".{ext}"
        unique = f"{base}_{uuid.uuid4().hex[:10]}{ext}"
        if max_length and len(unique) > max_length:
            unique = unique[:max_length]
        return unique

    def _save(self, name, content):
        name = self._normalize_name(name)
        data = content.read()
        if hasattr(content, "seek"):
            content.seek(0)

        content_type = getattr(content, "content_type", None) or mimetypes.guess_type(name)[0] or "application/octet-stream"

        self._client_bucket().upload(
            path=name,
            file=data,
            file_options={"content-type": content_type, "upsert": "true"},
        )
        return name

    def delete(self, name):
        if not name:
            return
        name = self._normalize_name(name)
        try:
            self._client_bucket().remove([name])
        except Exception:
            pass

    def exists(self, name):
        name = self._normalize_name(name)
        try:
            items = self._client_bucket().list(name.rsplit("/", 1)[0] or "")
            filename = name.rsplit("/", 1)[-1]
            return any(item.get("name") == filename for item in items)
        except Exception:
            return False

    def size(self, name):
        name = self._normalize_name(name)
        folder, filename = name.rsplit("/", 1) if "/" in name else ("", name)
        items = self._client_bucket().list(folder)
        for item in items:
            if item.get("name") == filename:
                meta = item.get("metadata") or {}
                return meta.get("size") or 0
        return 0

    def url(self, name):
        name = self._normalize_name(name)
        if not name:
            return ""

        if name.startswith("http://") or name.startswith("https://"):
            return name.replace("http://", "https://", 1)

        if self.public:
            base = settings.SUPABASE_URL.rstrip("/")
            return f"{base}/storage/v1/object/public/{self.bucket_name}/{name}"

        signed = self._client_bucket().create_signed_url(name, self.signed_ttl_seconds)
        return signed.get("signedURL") or signed.get("signedUrl") or ""

    def _open(self, name, mode="rb"):
        name = self._normalize_name(name)
        data = self._client_bucket().download(name)
        return ContentFile(data)


class SupabaseProfileStorage(SupabaseStorage):
    def __init__(self):
        super().__init__(
            settings.SUPABASE_PROFILE_BUCKET,
            public=settings.SUPABASE_PROFILE_BUCKET_PUBLIC,
            signed_ttl_seconds=settings.SUPABASE_SIGNED_URL_TTL,
        )


class SupabaseBodyStorage(SupabaseStorage):
    def __init__(self):
        super().__init__(
            settings.SUPABASE_BODY_BUCKET,
            public=False,
            signed_ttl_seconds=settings.SUPABASE_SIGNED_URL_TTL,
        )


def select_profile_storage():
    if is_supabase_configured():
        return SupabaseProfileStorage()
    from django.core.files.storage import FileSystemStorage

    return FileSystemStorage()


def select_body_storage():
    if is_supabase_configured():
        return SupabaseBodyStorage()
    from django.core.files.storage import FileSystemStorage

    return FileSystemStorage()
