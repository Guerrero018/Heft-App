from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import WorkoutSessionViewSet

router = DefaultRouter()
router.register(r'workouts', WorkoutSessionViewSet, basename='workout')

urlpatterns = [
    path('', include(router.urls)),
]
