import os
import django

# Setup Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.exercises.models import Exercise

def seed_exercises():
    exercises = [
        # Pectoral (Chest)
        {"name": "Press de Banca Plano", "muscle_group": "chest", "exercise_type": "barbell", "equipment": "Barra"},
        {"name": "Press de Banca Inclinado", "muscle_group": "chest", "exercise_type": "dumbbell", "equipment": "Mancuernas"},
        {"name": "Aperturas en Polea", "muscle_group": "chest", "exercise_type": "cable", "equipment": "Polea"},
        {"name": "Flexiones", "muscle_group": "chest", "exercise_type": "bodyweight", "equipment": "Ninguno"},
        
        # Dorsal (Back)
        {"name": "Dominadas", "muscle_group": "back", "exercise_type": "bodyweight", "equipment": "Barra de dominadas"},
        {"name": "Jalón al Pecho", "muscle_group": "back", "exercise_type": "cable", "equipment": "Polea"},
        {"name": "Remo con Barra", "muscle_group": "back", "exercise_type": "barbell", "equipment": "Barra"},
        {"name": "Remo Gironda", "muscle_group": "back", "exercise_type": "cable", "equipment": "Polea baja"},
        
        # Hombros (Shoulders)
        {"name": "Press Militar", "muscle_group": "shoulders", "exercise_type": "barbell", "equipment": "Barra"},
        {"name": "Elevaciones Laterales", "muscle_group": "shoulders", "exercise_type": "dumbbell", "equipment": "Mancuernas"},
        {"name": "Pájaros (Deltoides Posterior)", "muscle_group": "shoulders", "exercise_type": "dumbbell", "equipment": "Mancuernas"},
        
        # Piernas - Cuádriceps (Quadriceps)
        {"name": "Sentadilla Libre", "muscle_group": "quadriceps", "exercise_type": "barbell", "equipment": "Barra"},
        {"name": "Prensa de Piernas", "muscle_group": "quadriceps", "exercise_type": "machine", "equipment": "Máquina"},
        {"name": "Extensiones de Cuádriceps", "muscle_group": "quadriceps", "exercise_type": "machine", "equipment": "Máquina"},
        {"name": "Zancadas Búlgaras", "muscle_group": "quadriceps", "exercise_type": "dumbbell", "equipment": "Mancuernas"},
        
        # Piernas - Isquiotibiales (Hamstrings)
        {"name": "Peso Muerto Rumano", "muscle_group": "hamstrings", "exercise_type": "barbell", "equipment": "Barra"},
        {"name": "Curl Femoral Tumbado", "muscle_group": "hamstrings", "exercise_type": "machine", "equipment": "Máquina"},
        
        # Piernas - Glúteos (Glutes)
        {"name": "Hip Thrust", "muscle_group": "glutes", "exercise_type": "barbell", "equipment": "Barra"},
        
        # Piernas - Gemelos (Calves)
        {"name": "Elevación de Gemelos de Pie", "muscle_group": "calves", "exercise_type": "machine", "equipment": "Máquina"},
        
        # Brazos - Bíceps (Biceps)
        {"name": "Curl de Bíceps con Barra", "muscle_group": "biceps", "exercise_type": "barbell", "equipment": "Barra Z"},
        {"name": "Curl Martillo", "muscle_group": "biceps", "exercise_type": "dumbbell", "equipment": "Mancuernas"},
        {"name": "Curl en Polea Baja", "muscle_group": "biceps", "exercise_type": "cable", "equipment": "Polea"},
        
        # Brazos - Tríceps (Triceps)
        {"name": "Extensiones en Polea Alta", "muscle_group": "triceps", "exercise_type": "cable", "equipment": "Polea"},
        {"name": "Press Francés", "muscle_group": "triceps", "exercise_type": "barbell", "equipment": "Barra Z"},
        {"name": "Fondos en Paralelas", "muscle_group": "triceps", "exercise_type": "bodyweight", "equipment": "Paralelas"},
        
        # Core (Abs)
        {"name": "Crunch Abdominal", "muscle_group": "abs", "exercise_type": "bodyweight", "equipment": "Esterilla"},
        {"name": "Plancha (Plank)", "muscle_group": "abs", "exercise_type": "bodyweight", "equipment": "Esterilla"},
        {"name": "Rueda Abdominal", "muscle_group": "abs", "exercise_type": "other", "equipment": "Rueda Abdominal"},
    ]

    print(f"Borrando ejercicios globales antiguos...")
    Exercise.objects.filter(is_global=True).delete()

    print(f"Insertando {len(exercises)} ejercicios en el catálogo global...")
    created_count = 0
    for ex in exercises:
        # Create as global
        Exercise.objects.create(
            name=ex["name"],
            muscle_group=ex["muscle_group"],
            exercise_type=ex["exercise_type"],
            equipment=ex["equipment"],
            is_global=True,
            user=None
        )
        created_count += 1
        
    print(f"¡Éxito! {created_count} ejercicios añadidos a la base de datos de Neon.")

if __name__ == '__main__':
    seed_exercises()
