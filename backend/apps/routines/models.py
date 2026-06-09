from django.db import models
from django.conf import settings
from apps.exercises.models import Exercise

class Routine(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="routines")
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    is_public = models.BooleanField(
        default=False,
        help_text="Visible en la biblioteca pública de plantillas.",
    )
    is_official = models.BooleanField(
        default=False,
        help_text="Plantilla curada por Heft (staff).",
    )
    source_routine = models.ForeignKey(
        'self',
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='forks',
        help_text="Rutina de la que se importó esta copia.",
    )
    share_code = models.CharField(
        max_length=12,
        unique=True,
        null=True,
        blank=True,
        db_index=True,
        help_text="Código para compartir entre usuarios.",
    )
    published_at = models.DateTimeField(null=True, blank=True)
    times_imported = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [
            models.Index(fields=['is_public', '-published_at']),
            models.Index(fields=['is_official', '-times_imported']),
        ]

class RoutineExercise(models.Model):
    routine = models.ForeignKey(Routine, on_delete=models.CASCADE, related_name="exercises")
    exercise = models.ForeignKey(Exercise, on_delete=models.CASCADE, related_name="routines")
    order = models.IntegerField()
    target_sets = models.IntegerField()
    target_reps = models.IntegerField()
    target_weight = models.FloatField()
    rest_time_seconds = models.IntegerField(default=60)
    