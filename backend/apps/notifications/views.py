from django.utils import timezone
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import DeviceToken, UserNotificationPreferences
from .serializers import DeviceTokenSerializer, UserNotificationPreferencesSerializer


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
