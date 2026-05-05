from django.db import models
from django.conf import settings
from apps.exercises.models import Exercise

from django.utils import timezone

# Create your models here.

class WorkoutSession(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="workout_sessions")
    routine = models.ForeignKey('routines.Routine', on_delete=models.SET_NULL, null=True, blank=True, related_name="workouts")
    name = models.CharField(max_length=100, blank=True)
    date = models.DateField(auto_now_add=True)
    start_time = models.DateTimeField(default=timezone.now)
    end_time = models.DateTimeField(null=True, blank=True)
    notes = models.TextField(blank=True)
    is_completed = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.name or 'Workout'} - {self.date}"

class WorkoutSet(models.Model):
    workout_session = models.ForeignKey(WorkoutSession, on_delete=models.CASCADE, related_name="sets")
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="sets")
    set_number = models.IntegerField()
    weight = models.FloatField()
    reps = models.IntegerField()
    set_type = models.CharField(max_length=20, default='normal')
    rpe = models.IntegerField(null=True, blank=True)
    rir = models.IntegerField(null=True, blank=True)
    is_completed = models.BooleanField(default=False)
