from django.contrib import admin

from .models import DeviceToken, NotificationLog, UserNotificationPreferences


@admin.register(UserNotificationPreferences)
class UserNotificationPreferencesAdmin(admin.ModelAdmin):
    list_display = ("user", "all_enabled", "workout_enabled", "inactivity_enabled", "updated_at")
    search_fields = ("user__username", "user__email")
    list_filter = ("all_enabled", "workout_enabled", "body_progress_enabled", "weekly_summary_enabled")


@admin.register(DeviceToken)
class DeviceTokenAdmin(admin.ModelAdmin):
    list_display = ("user", "platform", "is_active", "created_at", "last_used_at")
    search_fields = ("user__username", "token")
    list_filter = ("platform", "is_active")


@admin.register(NotificationLog)
class NotificationLogAdmin(admin.ModelAdmin):
    list_display = ("user", "notification_type", "status", "title", "sent_at")
    search_fields = ("user__username", "title", "dedup_key")
    list_filter = ("notification_type", "status")
    readonly_fields = ("sent_at",)
