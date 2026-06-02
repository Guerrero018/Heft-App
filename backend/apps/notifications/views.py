import os

from django.conf import settings
from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .cron import run_scheduled_notification_jobs
from .models import DeviceToken, UserNotificationPreferences
from .serializers import DeviceTokenSerializer, UserNotificationPreferencesSerializer


def _cron_secret_valid(request) -> bool:
    expected = getattr(settings, "CRON_SECRET", "") or os.getenv("CRON_SECRET", "")
    if not expected:
        return False
    auth = request.headers.get("Authorization", "")
    if auth.startswith("Bearer "):
        return auth[7:].strip() == expected
    return request.headers.get("X-Cron-Secret", "").strip() == expected


class NotificationPreferencesView(APIView):
    """GET/PATCH the authenticated user's notification preferences.
    Creates the record with defaults on first GET if it doesn't exist yet."""

    permission_classes = [IsAuthenticated]

    def _get_or_create_prefs(self, user):
        prefs, _ = UserNotificationPreferences.objects.get_or_create(user=user)
        return prefs

    def get(self, request):
        prefs = self._get_or_create_prefs(request.user)
        serializer = UserNotificationPreferencesSerializer(prefs)
        return Response(serializer.data)

    def patch(self, request):
        prefs = self._get_or_create_prefs(request.user)
        serializer = UserNotificationPreferencesSerializer(
            prefs, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)


class DeviceTokenListCreateView(APIView):
    """POST a new FCM device token for the authenticated user.
    If the token already exists, update its owner and mark it active."""

    permission_classes = [IsAuthenticated]

    def get(self, request):
        tokens = DeviceToken.objects.filter(user=request.user, is_active=True)
        serializer = DeviceTokenSerializer(tokens, many=True)
        return Response(serializer.data)

    def post(self, request):
        token_value = request.data.get("token")
        platform = request.data.get("platform")

        if not token_value or not platform:
            return Response(
                {"detail": "Los campos 'token' y 'platform' son obligatorios."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        device_token, created = DeviceToken.objects.update_or_create(
            token=token_value,
            defaults={
                "user": request.user,
                "platform": platform,
                "is_active": True,
                "last_used_at": timezone.now(),
            },
        )

        serializer = DeviceTokenSerializer(device_token)
        response_status = status.HTTP_201_CREATED if created else status.HTTP_200_OK
        return Response(serializer.data, status=response_status)


class DeviceTokenDestroyView(APIView):
    """DELETE a device token by id (must belong to the authenticated user)."""

    permission_classes = [IsAuthenticated]

    def delete(self, request, pk):
        try:
            token = DeviceToken.objects.get(pk=pk, user=request.user)
        except DeviceToken.DoesNotExist:
            return Response(
                {"detail": "Token no encontrado."},
                status=status.HTTP_404_NOT_FOUND,
            )
        token.is_active = False
        token.save(update_fields=["is_active"])
        return Response(status=status.HTTP_204_NO_CONTENT)


class CronNotificationsView(APIView):
    """Dispara recordatorios programados (sustituto de Celery Beat vía HTTP).

    Protegido con CRON_SECRET:
      Authorization: Bearer <CRON_SECRET>
    o cabecera X-Cron-Secret: <CRON_SECRET>
    """

    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        return self._run(request)

    def get(self, request):
        return self._run(request)

    def _run(self, request):
        if not getattr(settings, "CRON_SECRET", ""):
            return Response(
                {"detail": "CRON_SECRET no configurado en el servidor."},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )
        if not _cron_secret_valid(request):
            return Response(
                {"detail": "No autorizado."},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        results = run_scheduled_notification_jobs()
        return Response({"ok": True, "results": results})
