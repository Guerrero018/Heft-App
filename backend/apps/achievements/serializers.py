from rest_framework import serializers

from .models import UserAchievement


class UserAchievementSerializer(serializers.ModelSerializer):
    id = serializers.CharField(source="achievement.slug")
    category = serializers.CharField(source="achievement.category")
    tier = serializers.CharField(source="achievement.tier", allow_null=True)
    title = serializers.CharField(source="achievement.title")
    subtitle = serializers.CharField(source="achievement.subtitle")
    description = serializers.CharField(source="achievement.description")
    icon_key = serializers.CharField(source="achievement.icon_key")
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = UserAchievement
        fields = (
            "id",
            "category",
            "tier",
            "title",
            "subtitle",
            "description",
            "icon_key",
            "image_url",
            "is_unlocked",
            "progress",
            "progress_label",
            "unlocked_at",
        )

    def get_image_url(self, obj: UserAchievement) -> str | None:
        if not obj.achievement.image:
            return None
        request = self.context.get("request")
        url = obj.achievement.image.url
        if request is not None:
            return request.build_absolute_uri(url)
        return url
