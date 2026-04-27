from django.db import models
from django.contrib.auth.models import AbstractUser

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
    weight = models.FloatField()
    date = models.DateField()
    notes = models.TextField(blank=True)
    photo = models.ImageField(upload_to="body_measures", blank=True, null=True)