from django.urls import path

from .views import (
    CronNotificationsView,
    DeviceTokenDestroyView,
    DeviceTokenListCreateView,
    NotificationPreferencesView,
)

urlpatterns = [
    path(
        "internal/cron/notifications/",
        CronNotificationsView.as_view(),
        name="cron_notifications",
    ),
    path("notifications/preferences/", NotificationPreferencesView.as_view(), name="notification_preferences"),
    path("notifications/devices/", DeviceTokenListCreateView.as_view(), name="notification_devices"),
    path("notifications/devices/<int:pk>/", DeviceTokenDestroyView.as_view(), name="notification_device_destroy"),
]
