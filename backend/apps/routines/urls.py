from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import RoutineTemplateViewSet, RoutineViewSet

router = DefaultRouter()
router.register(r'routines', RoutineViewSet, basename='routine')
router.register(r'routine-templates', RoutineTemplateViewSet, basename='routine-template')

urlpatterns = [
    path('', include(router.urls)),
]
