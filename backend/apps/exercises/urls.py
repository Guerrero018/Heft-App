from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ExerciseViewSet

router = DefaultRouter()
router.register(r'exercises', ExerciseViewSet, basename='exercise')

urlpatterns = [
    # Ruta manual para populares para asegurar la conexión
    path('exercises/popular/', ExerciseViewSet.as_view({'get': 'popular'}), name='exercise-popular'),
    path('', include(router.urls)),
]
