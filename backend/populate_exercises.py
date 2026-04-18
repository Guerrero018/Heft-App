import os
import django
import requests
import time
from deep_translator import GoogleTranslator

# Configurar el entorno de Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.exercises.models import Exercise

# --- CONFIGURACIÓN ---
RAPIDAPI_KEY = "TU_API_KEY_AQUI" # Reemplaza con tu key de RapidAPI
RAPIDAPI_HOST = "exercisedb.p.rapidapi.com"
URL = "https://exercisedb.p.rapidapi.com/exercises"

MUSCLE_MAPPING = {
    'back': 'back',
    'cardio': 'cardio',
    'chest': 'chest',
    'lower arms': 'forearms',
    'lower legs': 'calves',
    'neck': 'traps', # Lo mapeamos a trapecios/cuello
    'shoulders': 'shoulders',
    'upper arms': 'biceps', 
    'upper legs': 'quadriceps',
    'waist': 'abs',
}

TARGET_MAPPING = {
    'biceps': 'biceps',
    'triceps': 'triceps',
    'glutes': 'glutes',
    'hamstrings': 'hamstrings',
    'quads': 'quadriceps',
    'adductors': 'adductors',
    'abductors': 'abductors',
    'abs': 'abs',
    'serratus anterior': 'abs',
    'lats': 'back',
    'upper back': 'back',
    'spine': 'lower_back',
    'traps': 'traps',
    'levator scapulae': 'traps',
    'delts': 'shoulders',
    'pectorals': 'chest',
    'cardiovascular system': 'cardio',
}

EQUIPMENT_MAPPING = {
    'barbell': 'barbell',
    'dumbbell': 'dumbbell',
    'body weight': 'bodyweight',
    'cable': 'cable',
    'kettlebell': 'kettlebell',
    'machine': 'machine',
    'smith machine': 'smith_machine',
}

translator = GoogleTranslator(source='en', target='es')

def translate_safe(text):
    try:
        if not text: return ""
        return translator.translate(text)
    except Exception as e:
        print(f"Error traduciendo '{text}': {e}")
        return text

def populate():
    print("Iniciando limpieza de base de datos...")
    Exercise.objects.filter(is_global=True).delete()
    print("Base de datos limpia.")

    headers = {
        "X-RapidAPI-Key": RAPIDAPI_KEY,
        "X-RapidAPI-Host": RAPIDAPI_HOST
    }

    print(f"Obteniendo ejercicios de {URL}...")
    # Pedimos muchos para no paginar demasiado (el límite del basic tier es ~1300 en total)
    params = {"limit": "1500"} 
    
    response = requests.get(URL, headers=headers, params=params)
    
    if response.status_code != 200:
        print(f"Error al conectar con la API: {response.status_code}")
        print(response.text)
        return

    exercises_data = response.json()
    print(f"Se han obtenido {len(exercises_data)} ejercicios.")

    count = 0
    for data in exercises_data:
        try:
            name_en = data['name']
            
            # Mapeo de Músculos
            muscle = MUSCLE_MAPPING.get(data['bodyPart'], 'others')
            target = data['target']
            if target in TARGET_MAPPING:
                muscle = TARGET_MAPPING[target]
            
            # Mapeo de Equipo
            eq_en = data['equipment']
            eq_type = EQUIPMENT_MAPPING.get(eq_en, 'other')
            
            # Traducción
            print(f"[{count+1}/{len(exercises_data)}] Procesando: {name_en}...")
            name_es = translate_safe(name_en).capitalize()
            # La descripción la podemos armar con los campos o usar instructions
            instructions = data.get('instructions', [])
            instructions_es = [translate_safe(step) for step in instructions]
            
            Exercise.objects.create(
                name=name_es,
                muscle_group=muscle,
                equipment=eq_en.capitalize(),
                exercise_type=eq_type,
                instructions=instructions_es,
                gif_url=data.get('gifUrl'),
                is_global=True
            )
            count += 1
            
            # Pequeño delay para no saturar al traductor ni a la API
            if count % 10 == 0:
                time.sleep(1)
                
        except Exception as e:
            print(f"Error procesando ejercicio {data.get('name')}: {e}")

    print(f"¡Hecho! Se han insertado {count} ejercicios.")

if __name__ == "__main__":
    if RAPIDAPI_KEY == "TU_API_KEY_AQUI":
        print("ERROR: Por favor, introduce tu RAPIDAPI_KEY en el script.")
    else:
        populate()
