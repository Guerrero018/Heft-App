"""
URL configuration for heft_core project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.0/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from apps.users import views as users_views
from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)

from django.db import connection
from django.http import JsonResponse


def health_check(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
            cursor.fetchone()
    except Exception:
        return JsonResponse(
            {
                "status": "error",
                "db": "unavailable",
                "message": "Heft API is up but database is unreachable",
                "version": "1.0.1",
            },
            status=503,
        )

    return JsonResponse(
        {
            "status": "ok",
            "db": "ok",
            "message": "Heft API is awake!",
            "version": "1.0.1",
        }
    )

urlpatterns = [
    path('health/', health_check, name='health_check'),
    path('admin/', admin.site.urls),
    # JWT Authentication
    path('api/auth/register/', users_views.RegisterView.as_view(), name='auth_register'),
    path('api/auth/check-email/', users_views.CheckEmailView.as_view(), name='auth_check_email'),
    path('api/auth/password-reset/request/', users_views.PasswordResetRequestView.as_view(), name='auth_password_reset_request'),
    path('api/auth/password-reset/confirm/', users_views.PasswordResetConfirmView.as_view(), name='auth_password_reset_confirm'),
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('api/auth/profile/', include([
        path('', users_views.ProfileView.as_view(), name='auth_profile'),
        path('update/', users_views.UpdateProfileView.as_view(), name='auth_update_profile'),
    ])),
    # Social Auth
    path('api/auth/google/', include('allauth.socialaccount.providers.google.urls')),
    path('api/auth/social/', include('dj_rest_auth.registration.urls')),
    path('api/auth/social/google/', users_views.GoogleDirectLogin.as_view(), name='google_login'),
    # API endpoints
    path('api/', include([
        path('', include('apps.exercises.urls')),
        path('', include('apps.routines.urls')),
        path('', include('apps.workouts.urls')),
        path('', include('apps.statistics.urls')),
        path('', include('apps.users.urls')),
    ])),
] + static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
