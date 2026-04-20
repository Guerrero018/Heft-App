import os
import sys
import django
import json

# Añadir el directorio raíz al path para que Django funcione desde la carpeta scripts
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.exercises.models import Exercise

# --- CONFIGURACIÓN ---
INPUT_FILE = os.path.join(os.path.dirname(__file__), "exercises_data_es.json")

# Mapeos para Exercise Type (Tag Gris y Filtros en Flutter)
EQUIPMENT_TO_TYPE = {
    'barra': 'barra', 
    'mancuerna': 'mancuernas', 
    'maquina': 'maquina', 
    'machine': 'maquina',
    'leverage': 'maquina',
    'polea': 'polea', 
    'cable': 'polea',
    'peso corporal': 'peso_corporal', 
    'body weight': 'peso_corporal',
    'bodyweight': 'peso_corporal',
    'assisted': 'peso_corporal',
    'band': 'banda',
    'pesa rusa': 'pesa_rusa',
    'kettlebell': 'pesa_rusa',
    'máquina smith': 'maquina_smith',
    'smith machine': 'maquina_smith',
}

# Mapeo de refinamiento por Target (para que el filtro verde sea exacto)
TARGET_TO_MUSCLE = {
    'triceps': 'triceps', 'biceps': 'biceps', 'glutes': 'gluteos',
    'hamstrings': 'isquiotibiales', 'quads': 'cuadriceps', 'abs': 'abdominales',
    'calves': 'gemelos', 'adductors': 'aductores', 'abductors': 'abductores',
    'delts': 'hombros', 'pectorals': 'pecho', 'lats': 'espalda', 'traps': 'trapecios'
}

def populate():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Error: El archivo {INPUT_FILE} no existe.")
        return

    print(f"📦 Cargando datos desde {INPUT_FILE}...")
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        all_exercises = json.load(f)

    print(f"🗑️ Limpiando catálogo global actual...")
    Exercise.objects.filter(is_global=True).delete()

    print(f"🚀 Insertando {len(all_exercises)} ejercicios con lógica inteligente...")
    
    count = 0
    for ex in all_exercises:
        try:
            # 1. Determinar el grupo muscular refinado (usando target si es posible)
            raw_target = ex.get('target', '').lower()
            muscle = TARGET_TO_MUSCLE.get(raw_target)
            if not muscle:
                muscle = ex.get('bodyPart_es', 'otros').lower()
            
            # Normalización rápida para tildes/espacios en músculos comunes
            if 'abdominal' in muscle: muscle = 'abdominales'
            if 'bíceps' in muscle: muscle = 'biceps'
            if 'tríceps' in muscle: muscle = 'triceps'

            # 2. Determinar el tipo de ejercicio (para el filtro de equipamiento)
            eq_name = ex.get('equipment', '').lower() + " " + ex.get('equipment_es', '').lower()
            ex_type = "otro"
            for key, val in EQUIPMENT_TO_TYPE.items():
                if key in eq_name:
                    ex_type = val
                    break

            Exercise.objects.create(
                external_id=str(ex.get('id')),
                name=ex.get('name', 'Sin nombre').capitalize(),
                description=ex.get('description', ''),
                instructions=ex.get('instructions', []),
                muscle_group=muscle,
                target=ex.get('target', '').capitalize() if ex.get('target') else '',
                secondary_muscles=ex.get('secondaryMuscles', []),
                difficulty=ex.get('difficulty_es', 'intermedio'),
                category=ex.get('category', '').capitalize(),
                equipment=ex.get('equipment_es', 'Otro'),
                exercise_type=ex_type,
                gif_url=ex.get('gifUrl'),
                is_global=True
            )
            count += 1
            if count % 100 == 0:
                print(f"   ✅ {count} procesados...")
                
        except Exception as e:
            print(f"⚠️ Error en ejercicio {ex.get('id')}: {e}")

    print(f"\n✨ ¡HECHO! {count} ejercicios importados con inteligencia de filtros.")

if __name__ == "__main__":
    populate()
