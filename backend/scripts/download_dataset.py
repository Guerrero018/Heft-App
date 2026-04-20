import os
import requests
import json
import time
from dotenv import load_dotenv

# Cargar variables de entorno
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(os.path.dirname(BASE_DIR), ".env"))

# --- CONFIGURACIÓN ---
EXERCISE_DB_KEY = os.getenv("EXERCISE_DB_KEY")
RAPIDAPI_HOST = "exercisedb.p.rapidapi.com"
URL = "https://exercisedb.p.rapidapi.com/exercises"
OUTPUT_FILE = os.path.join(BASE_DIR, "exercises_data.json")

def download_all():
    print("🚀 Iniciando/Reanudando descarga del dataset...")
    all_exercises = []
    
    # Intentar cargar progreso previo
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
                all_exercises = json.load(f)
                print(f"   📂 Encontrado progreso previo: {len(all_exercises)} ejercicios.")
                # Reparar ejercicios antiguos sin gifUrl
                for ex in all_exercises:
                    if 'gifUrl' not in ex:
                        ex['gifUrl'] = f"https://exercisedb.p.rapidapi.com/image/{ex['id']}"
        except:
            pass

    headers = {
        "X-RapidAPI-Key": EXERCISE_DB_KEY,
        "X-RapidAPI-Host": RAPIDAPI_HOST
    }
    offset = len(all_exercises)
    limit = 50
    
    while len(all_exercises) < 1324:
        try:
            print(f"   -> Descargando ejercicios {offset} al {offset + limit}...")
            res = requests.get(URL, headers=headers, params={"limit": limit, "offset": offset})
            
            if res.status_code == 429:
                print("   [!] Límite 429 en RapidAPI. Esperando 60 segundos...")
                time.sleep(60)
                continue
            
            if res.status_code != 200:
                print(f"❌ Error {res.status_code}: {res.text}")
                break
                
            data = res.json()
            if not data:
                break
                
            # Inyectar gifUrl si falta
            for ex in data:
                if 'gifUrl' not in ex:
                    ex['gifUrl'] = f"https://exercisedb.p.rapidapi.com/image/{ex['id']}"
            
            all_exercises.extend(data)
            offset += len(data)
            print(f"   ✅ Llevamos {len(all_exercises)}/1324")
            
            # Guardado intermedio por seguridad
            with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
                json.dump(all_exercises, f, indent=4, ensure_ascii=False)
            
            time.sleep(1) # Pequeña pausa para no saturar
            
        except Exception as e:
            print(f"⚠️ Error inesperado: {e}")
            break

    print(f"\n🎉 ¡DESCARGA COMPLETADA! {len(all_exercises)} ejercicios guardados en {OUTPUT_FILE}")

if __name__ == "__main__":
    download_all()
