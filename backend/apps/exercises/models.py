from django.db import models
from django.conf import settings

class Exercise(models.Model):
    """
    Catálogo de ejercicios. Puede contener ejercicios globales de la app
    o ejercicios personalizados creados por los usuarios.
    """

    EXERCISE_TYPES = [
        ("barra", "Barra"),
        ("mancuernas", "Mancuernas"),
        ("maquina", "Máquina"),
        ("polea", "Polea"),
        ("peso_corporal", "Peso Corporal"),
        ("pesa_rusa", "Pesa Rusa"),
        ("maquina_smith", "Máquina Smith"),
        ("otro", "Otro"),
    ]

    MUSCLE_GROUPS = [
        ("pecho", "Pecho"),
        ("espalda", "Espalda"),
        ("hombros", "Hombros"),
        ("trapecios", "Trapecios"),
        ("cuadriceps", "Cuádriceps"),
        ("isquiotibiales", "Isquiotibiales"),
        ("gemelos", "Gemelos"),
        ("gluteos", "Glúteos"),
        ("aductores", "Aductores"),
        ("abductores", "Abductores"),
        ("biceps", "Bíceps"),
        ("triceps", "Tríceps"),
        ("antebrazos", "Antebrazos"),
        ("abdominales", "Abdominales"),
        ("espalda_baja", "Espalda Baja"),
        ("cardio", "Cardio"),
        ("otros", "Otros"),
    ]

    external_id = models.CharField(max_length=20, blank=True, null=True, help_text="ID original de ExerciseDB")
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    instructions = models.JSONField(default=list, blank=True, help_text="Lista de pasos para realizar el ejercicio")
    muscle_group = models.CharField(max_length=50, choices=MUSCLE_GROUPS)
    
    # Campos enriquecidos de ExerciseDB
    target = models.CharField(max_length=100, blank=True, null=True, help_text="Músculo objetivo específico")
    secondary_muscles = models.JSONField(default=list, blank=True, help_text="Lista de otros músculos involucrados")
    difficulty = models.CharField(max_length=50, blank=True, null=True)
    category = models.CharField(max_length=100, blank=True, null=True)
    
    equipment = models.CharField(
        max_length=100, blank=True, null=True
    )  # Ej: Barra, Mancuerna
    exercise_type = models.CharField(
        max_length=20, choices=EXERCISE_TYPES, default="otro"
    )
    gif_url = models.URLField(blank=True, null=True)

    is_global = models.BooleanField(
        default=False, help_text="True si es un ejercicio de la app"
    )

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="custom_exercises",
    )

    class Meta:
        unique_together = ("name", "user")

    def __str__(self):
        tipo = "Global" if self.is_global else f"Custom de {self.user.username}"
        return f"{self.name} ({tipo})"