from django.conf import settings
from django.db import models


class Achievement(models.Model):
    class Category(models.TextChoices):
        STRENGTH = "strength", "Fuerza"
        CONSISTENCY = "consistency", "Constancia"
        VOLUME = "volume", "Volumen"
        RECORDS = "records", "Récords"
        BODY_PROGRESS = "body_progress", "Progreso corporal"
        ROUTINES = "routines", "Rutinas"
        PROFILE = "profile", "Perfil"
        SPECIAL = "special", "Especiales"

    class Tier(models.TextChoices):
        BRONZE = "bronze", "Bronce"
        SILVER = "silver", "Plata"
        GOLD = "gold", "Oro"

    slug = models.SlugField(max_length=80, unique=True)
    category = models.CharField(max_length=32, choices=Category.choices)
    tier = models.CharField(
        max_length=16,
        choices=Tier.choices,
        null=True,
        blank=True,
    )
    title = models.CharField(max_length=120)
    subtitle = models.CharField(max_length=80)
    description = models.TextField()
    icon_key = models.CharField(
        max_length=64,
        help_text="Clave para mapear al icono Material en el frontend.",
    )
    image = models.ImageField(
        upload_to="achievements/",
        null=True,
        blank=True,
        help_text="Ilustración del logro (opcional).",
    )
    criteria = models.JSONField(
        default=dict,
        help_text="Parámetros para evaluar el logro (tipo, umbrales, etc.).",
    )
    sort_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["sort_order", "slug"]

    def __str__(self):
        return self.title


class UserAchievement(models.Model):
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="user_achievements",
    )
    achievement = models.ForeignKey(
        Achievement,
        on_delete=models.CASCADE,
        related_name="user_records",
    )
    is_unlocked = models.BooleanField(default=False)
    progress = models.FloatField(default=0.0)
    progress_label = models.CharField(max_length=80, blank=True)
    unlocked_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        unique_together = [("user", "achievement")]
        indexes = [
            models.Index(fields=["user", "is_unlocked"]),
        ]

    def __str__(self):
        status = "✓" if self.is_unlocked else "…"
        return f"{status} {self.user_id} — {self.achievement.slug}"
