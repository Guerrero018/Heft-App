from django.db import models
from django.conf import settings
from apps.exercises.models import Exercise

class Routine(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="routines")
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

class RoutineExercise(models.Model):
    routine = models.ForeignKey(Routine, on_delete=models.CASCADE, related_name="exercises")
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="routines")
    order = models.IntegerField()
    target_sets = models.IntegerField()
    target_reps = models.IntegerField()
    target_weight = models.FloatField()
    