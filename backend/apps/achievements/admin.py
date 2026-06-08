from django.contrib import admin

from .models import Achievement, UserAchievement


@admin.register(Achievement)
class AchievementAdmin(admin.ModelAdmin):
    list_display = (
        "title",
        "slug",
        "category",
        "tier",
        "has_image",
        "sort_order",
        "is_active",
    )
    list_filter = ("category", "tier", "is_active")
    search_fields = ("slug", "title")
    ordering = ("sort_order", "slug")
    readonly_fields = ("image_preview",)
    fields = (
        "slug",
        "category",
        "tier",
        "title",
        "subtitle",
        "description",
        "icon_key",
        "image",
        "image_preview",
        "criteria",
        "sort_order",
        "is_active",
    )

    @admin.display(boolean=True, description="Imagen")
    def has_image(self, obj: Achievement) -> bool:
        return bool(obj.image)

    @admin.display(description="Vista previa")
    def image_preview(self, obj: Achievement) -> str:
        if not obj.image:
            return "—"
        from django.utils.html import format_html

        return format_html(
            '<img src="{}" style="max-height:120px;border-radius:8px;" />',
            obj.image.url,
        )


@admin.register(UserAchievement)
class UserAchievementAdmin(admin.ModelAdmin):
    list_display = ("user", "achievement", "is_unlocked", "progress", "unlocked_at")
    list_filter = ("is_unlocked", "achievement__category")
    search_fields = ("user__username", "achievement__slug")
    raw_id_fields = ("user", "achievement")
