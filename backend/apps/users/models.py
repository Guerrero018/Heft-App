from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone

class User(AbstractUser):
    email = models.EmailField(unique=True)
    height = models.FloatField(null=True, blank=True, help_text="Height in cm")
    units_preference = models.CharField(
        max_length=10,
        choices=[('kg', 'Kilograms'), ('lbs', 'Pounds')],
        default='kg'
    )
    birth_date = models.DateField(null=True, blank=True)
    gender = models.CharField(max_length=20, null=True, blank=True)
    experience_level = models.CharField(max_length=50, null=True, blank=True)
    fitness_goal = models.CharField(max_length=100, null=True, blank=True)
    equipment = models.JSONField(default=list, blank=True) # Full gym, dumbbells, etc.
    workout_days_per_week = models.IntegerField(default=3)
    workout_duration_minutes = models.IntegerField(default=60)
    muscle_focus = models.JSONField(default=list, blank=True)
    
    weight = models.FloatField(null=True, blank=True, help_text="Current weight in kg")
    profile_picture = models.ImageField(upload_to="profile_pics", null=True, blank=True)
    
    is_onboarded = models.BooleanField(default=False)
    track_rpe = models.BooleanField(default=False, help_text="User preference to track RPE")

    def __str__(self):
        return self.username

class BodyMeasures(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="body_measures")
    weight = models.FloatField(help_text="Weight in kg")
    date = models.DateField()
    notes = models.TextField(blank=True)
    photo = models.ImageField(upload_to="body_measures", blank=True, null=True)
    # Optional body measurements (cm)
    neck_cm = models.FloatField(null=True, blank=True)
    chest_cm = models.FloatField(null=True, blank=True)
    waist_cm = models.FloatField(null=True, blank=True)
    hips_cm = models.FloatField(null=True, blank=True)
    shoulders_cm = models.FloatField(null=True, blank=True)
    bicep_left_cm = models.FloatField(null=True, blank=True)
    bicep_right_cm = models.FloatField(null=True, blank=True)
    thigh_left_cm = models.FloatField(null=True, blank=True)
    thigh_right_cm = models.FloatField(null=True, blank=True)

    class Meta:
        ordering = ["-date", "-id"]
        indexes = [
            models.Index(fields=["user", "-date"]),
        ]

    def __str__(self):
        return f"{self.user.username} — {self.date} ({self.weight} kg)"


class PasswordResetCode(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name="password_reset_codes",
    )
    code_hash = models.CharField(max_length=128)
    expires_at = models.DateTimeField()
    used_at = models.DateTimeField(null=True, blank=True)
    attempts = models.PositiveSmallIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]

    @property
    def is_expired(self):
        return timezone.now() >= self.expires_at

    @property
    def is_active(self):
        return self.used_at is None and not self.is_expired