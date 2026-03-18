from django.db import models
from django.conf import settings
from apps.exercises.models import Exercise

# Create your models here.

class WorkoutSession(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="workout_sessions")
    date = models.DateField()
    notes = models.TextField(blank=True)

class WorkoutSet(models.Model):
    workout_session = models.ForeignKey(WorkoutSession, on_delete=models.CASCADE, related_name="sets")
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="sets")
    set_number = models.IntegerField()
    weight = models.FloatField()
    reps = models.IntegerField()
    is_completed = models.BooleanField(default=False)
    
