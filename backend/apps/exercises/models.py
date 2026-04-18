from django.db import models
from django.conf import settings

class Exercise(models.Model):
    """
    Catálogo de ejercicios. Puede contener ejercicios globales de la app
    o ejercicios personalizados creados por los usuarios.
    """

    EXERCISE_TYPES = [
        ("barbell", "Barra"),
        ("dumbbell", "Mancuernas"),
        ("machine", "Máquina"),
        ("cable", "Polea"),
        ("bodyweight", "Peso Corporal"),
        ("kettlebell", "Pesa Rusa"),
        ("smith_machine", "Máquina Smith"),
        ("other", "Otro"),
    ]

    MUSCLE_GROUPS = [
        # Tronco Superior
        ("chest", "Pecho"),
        ("back", "Espalda"),
        ("shoulders", "Hombros"),
        ("traps", "Trapecios"),
        # Piernas
        ("quadriceps", "Cuádriceps"),
        ("hamstrings", "Isquiotibiales"),
        ("calves", "Gemelos"),
        ("glutes", "Glúteos"),
        ("adductors", "Aductores"),
        ("abductors", "Abductores"),
        # Brazos
        ("biceps", "Bíceps"),
        ("triceps", "Tríceps"),
        ("forearms", "Antebrazos"),
        # Core y Otros
        ("abs", "Abdominales"),
        ("lower_back", "Espalda Baja"),
        ("cardio", "Cardio"),
        ("others", "Otros"),
    ]

    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    instructions = models.JSONField(default=list, blank=True, help_text="Lista de pasos para realizar el ejercicio")
    muscle_group = models.CharField(max_length=50, choices=MUSCLE_GROUPS)
    equipment = models.CharField(
        max_length=100, blank=True, null=True
    )  # Ej: Barra, Mancuerna
    exercise_type = models.CharField(
        max_length=20, choices=EXERCISE_TYPES, default="other"
    )
    gif_url = models.URLField(blank=True, null=True)

    # 3. Lógica de propiedad (Global vs Custom)
    is_global = models.BooleanField(
        default=False, help_text="True si es un ejercicio de la app"
    )

    # Si is_global es False, este ejercicio pertenece a un usuario específico
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name="custom_exercises",
    )

    class Meta:
        # Evita que un usuario cree dos ejercicios con el mismo nombre exacto
        unique_together = ("name", "user")

    def __str__(self):
        tipo = "Global" if self.is_global else f"Custom de {self.user.username}"
        return f"{self.name} ({tipo})"