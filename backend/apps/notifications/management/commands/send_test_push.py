"""Envía una notificación push de prueba a un token FCM.

Uso:
  python manage.py send_test_push --token=EL_TOKEN_FCM
  python manage.py send_test_push --user=mi_usuario
"""

from django.contrib.auth import get_user_model
from django.core.management.base import BaseCommand, CommandError

from apps.notifications.firebase import send_push
from apps.notifications.models import DeviceToken

User = get_user_model()


class Command(BaseCommand):
    help = "Envía un push de prueba por FCM (token o usuario con dispositivo registrado)."

    def add_arguments(self, parser):
        parser.add_argument(
            "--token",
            help="Token FCM del dispositivo (línea 'FCM token:' en flutter run)",
        )
        parser.add_argument(
            "--user",
            help="Username de Django; usa el primer token activo del usuario",
        )
        parser.add_argument("--title", default="Prueba Heft")
        parser.add_argument("--body", default="Push desde el backend de Heft")

    def handle(self, *args, **options):
        token = options.get("token")
        username = options.get("user")

        if not token and not username:
            raise CommandError("Indica --token=... o --user=...")

        if username:
            try:
                user = User.objects.get(username=username)
            except User.DoesNotExist as exc:
                raise CommandError(f"Usuario no encontrado: {username}") from exc

            device = (
                DeviceToken.objects.filter(user=user, is_active=True)
                .order_by("-last_used_at")
                .first()
            )
            if not device:
                raise CommandError(
                    f"El usuario '{username}' no tiene tokens FCM activos. "
                    "Abre la app, inicia sesión y concede permisos."
                )
            token = device.token
            self.stdout.write(f"Token del usuario {username}: {token[:24]}…")

        ok = send_push(
            token=token,
            title=options["title"],
            body=options["body"],
        )
        if ok:
            self.stdout.write(self.style.SUCCESS("Push enviado correctamente."))
            self.stdout.write(
                "Minimiza la app en el móvil y revisa la bandeja de notificaciones."
            )
        else:
            raise CommandError(
                "No se pudo enviar. Revisa FIREBASE_CREDENTIALS_FILE en .env "
                "y que firebase-credentials.json exista."
            )
