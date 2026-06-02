from django.conf import settings
from django.db import models
from django.utils import timezone


class UserNotificationPreferences(models.Model):
    """One record per user with all notification preference toggles and schedules."""

    FREQUENCY_CHOICES = [
        ("weekly", "Semanal"),
        ("biweekly", "Quincenal"),
        ("monthly", "Mensual"),
    ]

    DAY_CHOICES = [
        (0, "Lunes"),
        (1, "Martes"),
        (2, "Miércoles"),
        (3, "Jueves"),
        (4, "Viernes"),
        (5, "Sábado"),
        (6, "Domingo"),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_preferences",
    )

    # Master switch
    all_enabled = models.BooleanField(default=True)

    # --- Workout reminders ---
    workout_enabled = models.BooleanField(default=True)
    # Days of week as JSON list of ints 0–6. Defaults to Mon–Fri.
    workout_days = models.JSONField(default=list)
    workout_hour = models.PositiveSmallIntegerField(default=9)
    workout_minute = models.PositiveSmallIntegerField(default=0)

    # --- Body progress reminders ---
    body_progress_enabled = models.BooleanField(default=True)
    body_progress_frequency = models.CharField(
        max_length=10, choices=FREQUENCY_CHOICES, default="weekly"
    )
    body_progress_day_of_week = models.PositiveSmallIntegerField(
        default=0, choices=DAY_CHOICES
    )
    body_progress_hour = models.PositiveSmallIntegerField(default=10)
    body_progress_minute = models.PositiveSmallIntegerField(default=0)

    # --- Weekly summary ---
    weekly_summary_enabled = models.BooleanField(default=True)
    weekly_summary_day_of_week = models.PositiveSmallIntegerField(
        default=6, choices=DAY_CHOICES
    )
    weekly_summary_hour = models.PositiveSmallIntegerField(default=20)
    weekly_summary_minute = models.PositiveSmallIntegerField(default=0)

    # --- Inactivity / motivation ---
    inactivity_enabled = models.BooleanField(default=True)
    inactivity_threshold_days = models.PositiveSmallIntegerField(default=3)

    # Timezone string, e.g. "Europe/Madrid"
    timezone = models.CharField(max_length=64, default="UTC")

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Notification Preferences"
        verbose_name_plural = "Notification Preferences"

    def __str__(self):
        return f"NotifPrefs({self.user.username})"

    def save(self, *args, **kwargs):
        if not self.workout_days:
            self.workout_days = [0, 1, 2, 3, 4]
        super().save(*args, **kwargs)


class DeviceToken(models.Model):
    """FCM device tokens per user, one per physical device."""

    PLATFORM_CHOICES = [
        ("android", "Android"),
        ("ios", "iOS"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.TextField(unique=True)
    platform = models.CharField(max_length=10, choices=PLATFORM_CHOICES)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(default=timezone.now)

    class Meta:
        indexes = [models.Index(fields=["user", "is_active"])]

    def __str__(self):
        return f"Token({self.user.username}, {self.platform})"


class NotificationLog(models.Model):
    """Audit log for every push notification sent or attempted."""

    TYPE_CHOICES = [
        ("workout_reminder", "Recordatorio de entrenamiento"),
        ("body_progress", "Recordatorio de progreso corporal"),
        ("weekly_summary", "Resumen semanal"),
        ("inactivity", "Motivación por inactividad"),
        ("achievement", "Logro o PR"),
    ]

    STATUS_CHOICES = [
        ("sent", "Enviado"),
        ("failed", "Fallido"),
        ("skipped", "Omitido"),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="notification_logs",
    )
    device_token = models.ForeignKey(
        DeviceToken,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="logs",
    )
    notification_type = models.CharField(max_length=30, choices=TYPE_CHOICES)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default="sent")
    title = models.CharField(max_length=255, blank=True)
    body = models.TextField(blank=True)
    error_message = models.TextField(blank=True)
    sent_at = models.DateTimeField(auto_now_add=True)
    # ISO date key used for deduplication, e.g. "2026-06-02"
    dedup_key = models.CharField(max_length=64, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=["user", "notification_type", "dedup_key"]),
            models.Index(fields=["sent_at"]),
        ]

    def __str__(self):
        return f"Log({self.user.username}, {self.notification_type}, {self.status})"
