from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import BodyMeasuresViewSet

router = DefaultRouter()
router.register(r"body-measures", BodyMeasuresViewSet, basename="body-measures")

urlpatterns = [
    path("", include(router.urls)),
]
