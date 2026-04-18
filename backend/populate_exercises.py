import os
import django
import requests
import time
import json
from google import genai

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.exercises.models import Exercise

# --- CONFIGURACIÓN ---
EXERCISE_DB_KEY = "a20356a4bemsh90baf9002ebbf02p1cf983jsnc41f23636002"
GEMINI_API_KEY = "AIzaSyCiN4_ps4wcPC3UBUdJ5kTPO6DM512i_e4"
RAPIDAPI_HOST = "exercisedb.p.rapidapi.com"
URL = "https://exercisedb.p.rapidapi.com/exercises"

# Modelos para intentar en orden de preferencia
MODELS_TO_TRY = ["gemini-2.0-flash", "gemini-flash-latest", "gemini-2.5-flash"]
current_model_idx = 0

client = genai.Client(api_key=GEMINI_API_KEY)

MUSCLE_MAPPING = {
    'back': 'back', 'cardio': 'cardio', 'chest': 'chest', 'lower arms': 'forearms',
    'lower legs': 'calves', 'neck': 'traps', 'shoulders': 'shoulders',
    'upper arms': 'biceps', 'upper legs': 'quadriceps', 'waist': 'abs'
}

TARGET_MAPPING = {
    'biceps': 'biceps', 'triceps': 'triceps', 'glutes': 'glutes', 'hamstrings': 'hamstrings',
    'quads': 'quadriceps', 'adductors': 'adductors', 'abductors': 'abductors', 'abs': 'abs',
    'serratus anterior': 'abs', 'lats': 'back', 'upper back': 'back', 'spine': 'lower_back',
    'traps': 'traps', 'levator scapulae': 'traps', 'delts': 'shoulders', 'pectorals': 'chest',
    'cardiovascular system': 'cardio'
}

EQUIPMENT_MAPPING = {
    'barbell': 'barbell', 'dumbbell': 'dumbbell', 'body weight': 'bodyweight',
    'cable': 'cable', 'kettlebell': 'kettlebell', 'machine': 'machine', 'smith machine': 'smith_machine'
}

def translate_mega_batch(batch):
    global current_model_idx
    model_id = MODELS_TO_TRY[current_model_idx]
    
    prompt = f"""
    Eres un experto en fitness. Traduce esta lista JSON al español.
    Nombres técnicos (Curl, Press, Polea).
    Traduce 'name' e 'instructions'.
    Response solo JSON.
    DATA:
    {json.dumps(batch)}
    """
    
    try:
        response = client.models.generate_content(
            model=model_id,
            config=genai.types.GenerateContentConfig(response_mime_type="application/json"),
            contents=prompt
        )
        return json.loads(response.text)
    except Exception as e:
        error_msg = str(e)
        print(f"   [Error con {model_id}]: {error_msg[:100]}...")
        
        # Si el error es de cuota o no encontrado, probamos el siguiente modelo
        if current_model_idx < len(MODELS_TO_TRY) - 1:
            print(f"   Cambiando al siguiente modelo disponible...")
            current_model_idx += 1
            return translate_mega_batch(batch) # Reintento recursivo con el nuevo modelo
        
        raise e

def populate():
    print("1. Limpiando ejercicios globales...")
    Exercise.objects.filter(is_global=True).delete()
    
    print("2. Descargando Dataset de ExerciseDB (vía RapidAPI)...")
    all_raw = []
    offset = 0
    limit = 10 # Forzamos a 10 porque es lo que la API Free suele devolver
    
    headers = {"X-RapidAPI-Key": EXERCISE_DB_KEY, "X-RapidAPI-Host": RAPIDAPI_HOST}
    
    while True:
        try:
            res = requests.get(URL, headers=headers, params={"limit": limit, "offset": offset})
            if res.status_code != 200: break
            data = res.json()
            if not data: break
            all_raw.extend(data)
            if len(all_raw) % 50 == 0:
                print(f"   -> Descargados {len(all_raw)} ejercicios...")
            offset += len(data) # Incrementamos por lo recibido realmente
            if len(data) == 0: break
            # Limite preventivo para no tardar mil años en pruebas
            # if len(all_raw) >= 1500: break
        except: break
    
    print(f"\n3. Descarga completa: {len(all_raw)} ejercicios encontrados.")
    print("4. Iniciando traducción inteligente por bloques...")
    
    mega_batch_size = 100 # Reducimos un poco para asegurar que no exceda el limite de respuesta
    final_count = 0
    i = 0
    
    while i < len(all_raw):
        chunk = all_raw[i:i + mega_batch_size]
        to_translate = [{"id": x['id'], "name": x['name'], "instructions": x.get('instructions', [])} for x in chunk]
        
        print(f"\n--- MEGA-LOTE {i//mega_batch_size + 1} ({i}/{len(all_raw)}) ---")
        
        try:
            translated_data = translate_mega_batch(to_translate)
            
            if not translated_data:
                print("   !!! La IA devolvió datos vacíos. Reintentando...")
                time.sleep(10)
                continue

            trans_map = {str(t['id']): t for t in translated_data}
            
            for raw_ex in chunk:
                try:
                    trans_ex = trans_map.get(str(raw_ex['id']), raw_ex)
                    
                    muscle = MUSCLE_MAPPING.get(raw_ex['bodyPart'], 'others')
                    target = raw_ex['target']
                    if target in TARGET_MAPPING: muscle = TARGET_MAPPING[target]
                    
                    Exercise.objects.create(
                        name=trans_ex['name'].capitalize(),
                        muscle_group=muscle,
                        equipment=raw_ex.get('equipment', 'other').capitalize(),
                        exercise_type=EQUIPMENT_MAPPING.get(raw_ex.get('equipment'), 'other'),
                        instructions=trans_ex.get('instructions', []),
                        gif_url=raw_ex.get('gifUrl'),
                        is_global=True
                    )
                    final_count += 1
                except: pass
            
            i += mega_batch_size
            print(f"   Progreso: {final_count} guardados.")
            time.sleep(10) # Pausa estratégica para la cuota
            
        except Exception as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                print("   Límite excedido. Esperando 60s...")
                time.sleep(60)
            else:
                print(f"   Error: {e}. Reintentando en 15s...")
                time.sleep(15)

    print(f"\n¡INCERCIÓN FINALIZADA! Total: {final_count} ejercicios.")

if __name__ == "__main__":
    populate()
