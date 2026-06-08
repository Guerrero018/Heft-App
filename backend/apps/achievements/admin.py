from django.contrib import admin

from .models import Achievement, UserAchievement


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = ("title", "slug", "category", "tier", "sort_order", "is_active")
    list_filter = ("category", "tier", "is_active")
    search_fields = ("slug", "title")
    ordering = ("sort_order", "slug")


@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    list_display = ("user", "achievement", "is_unlocked", "progress", "unlocked_at")
    list_filter = ("is_unlocked", "achievement__category")
    search_fields = ("user__username", "achievement__slug")
    raw_id_fields = ("user", "achievement")
