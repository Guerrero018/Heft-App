import os
import secrets
from datetime import timedelta

from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.client import OAuth2Client
from dj_rest_auth.registration.views import SocialLoginView
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.hashers import make_password
from django.core.mail import send_mail
from django.utils import timezone
from google.auth.transport import requests as google_requests
from google.oauth2 import id_token
from django.db.models import Q
from rest_framework import generics, permissions, status, viewsets, filters
from rest_framework.decorators import action
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.tokens import RefreshToken

from .models import BodyMeasures, PasswordResetCode
from .serializers import (
    BodyMeasuresSerializer,
    CustomUserSerializer,
    PasswordResetConfirmSerializer,
    PasswordResetRequestSerializer,
    RegisterSerializer,
)

User = get_user_model()


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer


class CheckEmailView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        email = request.data.get('email', '').lower().strip()
        exists = User.objects.filter(email__iexact=email).exists()
        return Response({'exists': exists})

class UpdateProfileView(generics.UpdateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = CustomUserSerializer
    parser_classes = (MultiPartParser, FormParser, JSONParser)

    def get_object(self):
        return self.request.user

    def post(self, request, *args, **kwargs):
        """Permitir POST para actualizaciones (más robusto para subida de archivos)"""
        return self.partial_update(request, *args, **kwargs)

    def perform_update(self, serializer):
        serializer.save(is_onboarded=True)

class ProfileView(generics.RetrieveAPIView):
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = CustomUserSerializer

    def get_object(self):
        return self.request.user

    def get(self, request, *args, **kwargs):
        serializer = self.get_serializer(self.get_object(), context={'request': request})
        return Response(serializer.data)


class PasswordResetRequestView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = PasswordResetRequestSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email = serializer.validated_data["email"]
        user = User.objects.get(email__iexact=email)
        code = f"{secrets.randbelow(1000000):06d}"
        expires_at = timezone.now() + timedelta(minutes=15)

        PasswordResetCode.objects.filter(
            user=user,
            used_at__isnull=True,
        ).update(used_at=timezone.now())

        PasswordResetCode.objects.create(
            user=user,
            code_hash=make_password(code),
            expires_at=expires_at,
        )

        send_mail(
            subject="Heft - Recuperación de contraseña",
            message=(
                f"Tu código de recuperación es: {code}\n\n"
                "Este código caduca en 15 minutos.\n"
                "Si no has solicitado este cambio, puedes ignorar este correo."
            ),
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )

        response_data = {
            "detail": "Te hemos enviado un código de recuperación por email.",
        }
        if settings.DEBUG:
            response_data["debug_code"] = code

        return Response(response_data, status=status.HTTP_200_OK)


class PasswordResetConfirmView(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        serializer = PasswordResetConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(
            {"detail": "Tu contraseña se ha actualizado correctamente."},
            status=status.HTTP_200_OK,
        )

class GoogleDirectLogin(APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request):
        token = request.data.get('access_token') or request.data.get('id_token')
        if not token:
            return Response({'detail': 'No se proporcionó el token'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Reutilizar el Web Client ID de settings
            client_id = os.getenv('GOOGLE_WEB_CLIENT_ID')
            
            # Verificar el token con Google
            idinfo = id_token.verify_oauth2_token(token, google_requests.Request(), client_id)

            # Extraer info (Google devuelve 'sub' como ID único del usuario)
            email = idinfo['email'].lower().strip()
            username = email.split('@')[0] # Usar el email como base para el username
            
            # 1. Buscar o crear el usuario en Neon
            user, created = User.objects.get_or_create(
                email=email,
                defaults={'username': username}
            )

            # 2. Generar tokens JWT de Heft
            refresh = RefreshToken.for_user(user)
            
            return Response({
                'access': str(refresh.access_token),
                'refresh': str(refresh),
                'user': CustomUserSerializer(user, context={'request': request}).data
            })

        except ValueError as e:
            return Response({'detail': f'Token inválido: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'detail': f'Error del servidor: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class GoogleLogin(SocialLoginView):
    adapter_class = GoogleOAuth2Adapter
    callback_url = "https://heft-backend-ywi0.onrender.com/accounts/google/login/callback/" 
    client_class = OAuth2Client


def _sync_user_weight_from_measures(user):
    latest = BodyMeasures.objects.filter(user=user).order_by("-date", "-id").first()
    if latest:
        user.weight = latest.weight
        user.save(update_fields=["weight"])


class BodyMeasuresViewSet(viewsets.ModelViewSet):
    serializer_class = BodyMeasuresSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = (MultiPartParser, FormParser, JSONParser)
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ["date", "weight"]
    ordering = ["-date"]

    def get_queryset(self):
        qs = BodyMeasures.objects.filter(user=self.request.user).prefetch_related(
            "measure_photos"
        )
        if self.request.query_params.get("has_photo") == "true":
            qs = qs.filter(measure_photos__isnull=False).distinct()
        return qs

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["request"] = self.request
        return context

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
        _sync_user_weight_from_measures(self.request.user)

    def perform_update(self, serializer):
        serializer.save()
        _sync_user_weight_from_measures(self.request.user)

    def perform_destroy(self, instance):
        instance.delete()
        _sync_user_weight_from_measures(self.request.user)

    @action(detail=False, methods=["get"], url_path="weight-history")
    def weight_history(self, request):
        rows = (
            self.get_queryset()
            .order_by("date", "id")
            .values("date", "weight")
        )
        return Response(
            [
                {"date": row["date"].isoformat(), "weight": row["weight"]}
                for row in rows
            ]
        )

    @action(detail=False, methods=["get"], url_path="progress-photos")
    def progress_photos(self, request):
        qs = self.get_queryset().filter(measure_photos__isnull=False).distinct()
        serializer = self.get_serializer(qs, many=True)
        return Response(serializer.data)
