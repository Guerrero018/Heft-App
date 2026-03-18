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
        ("chest", "Pectoral"),
        ("back", "Dorsal"),
        ("shoulders", "Hombros"),
        # Piernas (Desglosadas)
        ("quadriceps", "Cuádriceps"),
        ("hamstrings", "Isquiotibiales (Femorales)"),
        ("calves", "Gemelos"),
        ("glutes", "Glúteos"),
        ("adductors", "Adductores"),
        ("abductors", "Abductores"),
        # Brazos (Desglosados)
        ("biceps", "Bíceps"),
        ("triceps", "Tríceps"),
        ("forearms", "Antebrazos"),
        # Core
        ("abs", "Abdominales"),
        # Otros
        ("others", "Otros"),
    ]

    name = models.CharField(max_length=150)
    muscle_group = models.CharField(max_length=50, choices=MUSCLE_GROUPS)
    equipment = models.CharField(
        max_length=50, blank=True, null=True
    )  # Ej: Barra, Mancuerna
    exercise_type = models.CharField(
        max_length=20, choices=EXERCISE_TYPES, default="weight_reps"
    )

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