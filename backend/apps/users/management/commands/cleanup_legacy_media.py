from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand

from apps.users.media_utils import is_legacy_storage_path
from apps.users.models import BodyMeasurePhoto, BodyMeasures
from apps.users.storage.supabase_storage import SupabaseBodyStorage, SupabaseProfileStorage

User = get_user_model()


class Command(BaseCommand):
    help = "Quita rutas de foto huérfanas (Cloudinary/local) que no existen en Supabase."

    def handle(self, *args, **options):
        if not settings.USE_SUPABASE_STORAGE:
            self.stdout.write("Supabase no configurado; nada que limpiar.")
            return

        profile_storage = SupabaseProfileStorage()
        body_storage = SupabaseBodyStorage()
        cleared_profiles = 0
        cleared_photos = 0

        for user in User.objects.exclude(profile_picture="").exclude(
            profile_picture__isnull=True
        ):
            name = user.profile_picture.name
            if name.startswith("http"):
                continue
            missing = is_legacy_storage_path(name, field="profile") or not profile_storage.exists(
                name
            )
            if missing:
                user.profile_picture.delete(save=True)
                cleared_profiles += 1
                self.stdout.write(f"Perfil limpiado: user {user.pk} ({name})")

        for photo in BodyMeasurePhoto.objects.select_related("body_measure"):
            name = photo.image.name
            if name.startswith("http"):
                continue
            missing = is_legacy_storage_path(name, field="body") or not body_storage.exists(
                name
            )
            if missing:
                photo.delete()
                cleared_photos += 1
                self.stdout.write(
                    f"Foto progreso limpiada: photo {photo.pk} entry {photo.body_measure_id} ({name})"
                )

        self.stdout.write(
            self.style.SUCCESS(
                f"Listo: {cleared_profiles} perfiles, {cleared_photos} fotos de progreso."
            )
        )
