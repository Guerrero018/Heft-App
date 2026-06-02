from rest_framework import serializers

from .models import DeviceToken, UserNotificationPreferences


class UserNotificationPreferencesSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserNotificationPreferences
        exclude = ("user",)
        read_only_fields = ("updated_at",)

    def validate_workout_hour(self, value):
        if not 0 <= value <= 23:
            raise serializers.ValidationError("La hora debe estar entre 0 y 23.")
        return value

    def validate_workout_minute(self, value):
        if not 0 <= value <= 59:
            raise serializers.ValidationError("Los minutos deben estar entre 0 y 59.")
        return value

    def validate_body_progress_hour(self, value):
        if not 0 <= value <= 23:
            raise serializers.ValidationError("La hora debe estar entre 0 y 23.")
        return value

    def validate_body_progress_minute(self, value):
        if not 0 <= value <= 59:
            raise serializers.ValidationError("Los minutos deben estar entre 0 y 59.")
        return value

    def validate_weekly_summary_hour(self, value):
        if not 0 <= value <= 23:
            raise serializers.ValidationError("La hora debe estar entre 0 y 23.")
        return value

    def validate_weekly_summary_minute(self, value):
        if not 0 <= value <= 59:
            raise serializers.ValidationError("Los minutos deben estar entre 0 y 59.")
        return value

    def validate_workout_days(self, value):
        if not isinstance(value, list):
            raise serializers.ValidationError("workout_days debe ser una lista.")
        for day in value:
            if day not in range(7):
                raise serializers.ValidationError(
                    "Cada día debe ser un entero entre 0 (lunes) y 6 (domingo)."
                )
        return value

    def validate_inactivity_threshold_days(self, value):
        if not 1 <= value <= 30:
            raise serializers.ValidationError("El umbral debe estar entre 1 y 30 días.")
        return value


class DeviceTokenSerializer(serializers.ModelSerializer):
    class Meta:
        model = DeviceToken
        fields = ("id", "token", "platform", "is_active", "created_at", "last_used_at")
        read_only_fields = ("id", "created_at", "last_used_at")

    def validate_platform(self, value):
        if value not in ("android", "ios"):
            raise serializers.ValidationError("La plataforma debe ser 'android' o 'ios'.")
        return value
