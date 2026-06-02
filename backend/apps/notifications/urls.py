from django.urls import path

from .views import (
    DeviceTokenDestroyView,
    DeviceTokenListCreateView,
    NotificationPreferencesView,
)

urlpatterns = [
    path("notifications/preferences/", NotificationPreferencesView.as_view(), name="notification_preferences"),
    path("notifications/devices/", DeviceTokenListCreateView.as_view(), name="notification_devices"),
    path("notifications/devices/<int:pk>/", DeviceTokenDestroyView.as_view(), name="notification_device_destroy"),
]
