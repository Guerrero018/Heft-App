import os
from rest_framework import generics, permissions
from django.contrib.auth import get_user_model
from .serializers import RegisterSerializer

from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.client import OAuth2Client
from dj_rest_auth.registration.views import SocialLoginView

User = get_user_model()

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = RegisterSerializer

from google.oauth2 import id_token
from google.auth.transport import requests as google_requests
from django.conf import settings
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework_simplejwt.tokens import RefreshToken
from .serializers import CustomUserSerializer

class UpdateProfileView(generics.UpdateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.IsAuthenticated,)
    serializer_class = CustomUserSerializer

    def get_object(self):
        return self.request.user

    def perform_update(self, serializer):
        serializer.save(is_onboarded=True)

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
                'user': CustomUserSerializer(user).data
            })

        except ValueError as e:
            return Response({'detail': f'Token inválido: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            return Response({'detail': f'Error del servidor: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class GoogleLogin(SocialLoginView):
    adapter_class = GoogleOAuth2Adapter
    callback_url = "https://heft-backend-ywi0.onrender.com/accounts/google/login/callback/" 
    client_class = OAuth2Client
