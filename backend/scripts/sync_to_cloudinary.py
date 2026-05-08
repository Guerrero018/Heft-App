import os
import sys
import django
import requests
import cloudinary
import cloudinary.uploader
from cloudinary.utils import cloudinary_url

# Configurar el entorno de Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.exercises.models import Exercise
from django.conf import settings
from dotenv import load_dotenv

# Leer .env
env_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), '.env')
load_dotenv(env_path)

# Configurar Cloudinary
cloudinary.config(
    cloud_name=os.getenv('CLOUDINARY_CLOUD_NAME'),
    api_key=os.getenv('CLOUDINARY_API_KEY'),
    api_secret=os.getenv('CLOUDINARY_API_SECRET'),
    secure=True
)

import time

def sync_gifs(limit=20):
    # Solo ejercicios globales que tengan external_id y que NO tengan ya un link de Cloudinary
    exercises = Exercise.objects.filter(
        is_global=True,
        external_id__isnull=False
    ).exclude(gif_url__icontains="cloudinary")[:limit]

    total_pending = exercises.count()
    if total_pending == 0:
        print("✅ No hay ejercicios pendientes de sincronizar en este lote.")
        return

    print(f"🚀 Iniciando sincronización de un lote de {total_pending} ejercicios...")
    
    api_key = os.getenv('EXERCISE_DB_KEY')
    count = 0

    for ex in exercises:
        try:
            download_url = f"https://exercisedb.p.rapidapi.com/image?exerciseId={ex.external_id}&resolution=180"
            headers = {
                "X-RapidAPI-Key": api_key,
                "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
            }

            print(f"📥 [{count+1}/{total_pending}] Procesando: {ex.name}...")
            
            success = False
            for attempt in range(3): # Hasta 3 intentos por ejercicio
                time.sleep(5) # Espera base reducida para el primer intento
                
                response = requests.get(download_url, headers=headers, timeout=15)
                
                # DIAGNÓSTICO: Imprimir headers de límite si existen
                remaining = response.headers.get('X-RateLimit-Requests-Remaining')
                reset = response.headers.get('X-RateLimit-Requests-Reset')
                limit = response.headers.get('X-RateLimit-Requests-Limit')
                
                if response.status_code == 200:
                    success = True
                    break
                elif response.status_code == 429:
                    print(f"\n🔍 [DIAGNÓSTICO 429]")
                    print(f"   - Límite Total: {limit}")
                    print(f"   - Peticiones Restantes: {remaining}")
                    print(f"   - Tiempo para Reset: {reset} segundos")
                    print(f"   - Mensaje API: {response.text[:100]}")
                    
                    wait_time = 65
                    print(f"   ⏳ Reintento {attempt+1}/3 en {wait_time}s...")
                    time.sleep(wait_time)
                else:
                    print(f"   ⚠️ Error {response.status_code}: {response.text[:100]}")
                    break

            if not success:
                print(f"   ❌ No se pudo descargar {ex.name} tras varios intentos. Saltando...")
                continue

            # 2. Subir a Cloudinary
            upload_result = cloudinary.uploader.upload(
                response.content,
                folder="heft/exercises",
                public_id=f"ex_{ex.external_id}",
                resource_type="image",
                overwrite=True
            )

            # 3. Guardar nueva URL en la base de datos
            new_url = upload_result.get('secure_url')
            ex.gif_url = new_url
            ex.save()

            count += 1
            print(f"   ✅ Sincronizado en Cloudinary.")

        except Exception as e:
            print(f"❌ Error inesperado en {ex.name}: {e}")

    print(f"\n✨ Lote finalizado. Se han sincronizado {count} ejercicios.")
    remaining = Exercise.objects.filter(is_global=True).exclude(gif_url__icontains="cloudinary").count()
    print(f"📊 Quedan {remaining} ejercicios por migrar en total.")

if __name__ == "__main__":
    sync_gifs()
