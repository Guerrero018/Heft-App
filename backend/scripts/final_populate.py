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
# Ahora que estamos en scripts/, el archivo está en la misma carpeta
INPUT_FILE = os.path.join(os.path.dirname(__file__), "exercises_data_es.json")

def populate():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Error: El archivo {INPUT_FILE} no existe. Primero termina la traducción.")
        return

    print(f"📦 Cargando datos enriquecidos desde {INPUT_FILE}...")
    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        all_exercises = json.load(f)

    print(f"🗑️ Limpiando catálogo global actual...")
    Exercise.objects.filter(is_global=True).delete()

    print(f"🚀 Insertando {len(all_exercises)} ejercicios con todo lujo de detalles...")
    
    count = 0
    for ex in all_exercises:
        try:
            # Creamos el ejercicio mapeando los campos del JSON a nuestro modelo actualizado
            Exercise.objects.create(
                external_id=str(ex.get('id')),
                name=ex.get('name', 'Sin nombre').capitalize(),
                description=ex.get('description', ''),
                instructions=ex.get('instructions', []),
                
                # Campos de organización
                muscle_group=ex.get('bodyPart_es', 'otros').lower(),
                target=ex.get('target', '').capitalize() if ex.get('target') else ex.get('target'),
                secondary_muscles=ex.get('secondaryMuscles', []),
                difficulty=ex.get('difficulty_es', 'intermedio'),
                category=ex.get('category', '').capitalize(),
                
                # Equipamiento y GIFs
                equipment=ex.get('equipment_es', 'Otro'),
                exercise_type="otro", # Esto se puede pulir luego segun el equipamiento
                gif_url=ex.get('gifUrl'),
                
                is_global=True
            )
            count += 1
            if count % 100 == 0:
                print(f"   ✅ {count} procesados...")
                
        except Exception as e:
            print(f"⚠️ Error en ejercicio {ex.get('id')}: {e}")

    print(f"\n✨ ¡CATÁLOGO COMPLETO! {count} ejercicios importados con éxito.")

if __name__ == "__main__":
    populate()
