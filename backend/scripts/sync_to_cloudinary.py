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

def sync_gifs():
    # Solo ejercicios globales que tengan external_id y que NO tengan ya un link de Cloudinary
    exercises = Exercise.objects.filter(
        is_global=True,
        external_id__isnull=False
    ).exclude(gif_url__icontains="cloudinary")

    total_pending = exercises.count()
    print(f"🚀 Iniciando sincronización de {total_pending} ejercicios pendientes...")
    
    # Intentamos obtener la key del .env (prioridad a la que usa el frontend si está disponible)
    api_key = os.getenv('EXERCISE_DB_KEY')
    
    count = 0
    # Límite por ejecución para evitar bloqueos largos (ajustable)
    limit = 500 

    for ex in exercises:
        if count >= limit:
            print(f"🛑 Se alcanzó el límite de {limit} por esta ejecución.")
            break

        try:
            # 1. Construir URL oficial de descarga (V2 a 180p)
            download_url = f"https://exercisedb.p.rapidapi.com/image?exerciseId={ex.external_id}&resolution=180"
            headers = {
                "X-RapidAPI-Key": api_key,
                "X-RapidAPI-Host": "exercisedb.p.rapidapi.com"
            }

            print(f"📥 [{count+1}/{total_pending}] Descargando: {ex.name} ({ex.external_id})...")
            response = requests.get(download_url, headers=headers, timeout=15)

            if response.status_code == 429:
                print("\n❌ ERROR 429: Cuota de RapidAPI agotada para esta clave.")
                print("💡 Tip: Espera a mañana o cambia la EXERCISE_DB_KEY en el .env")
                break
            
            if response.status_code != 200:
                print(f"⚠️ Fallo al descargar {ex.name}: Código {response.status_code}")
                # Si es un error de ID no encontrado, podríamos marcarlo para no reintentar
                continue

            # 2. Subir a Cloudinary
            # public_id basado en external_id para evitar duplicados en Cloudinary
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
            print(f"✅ Sincronizado: {new_url}")

        except Exception as e:
            print(f"❌ Error inesperado en {ex.name}: {e}")

    print(f"\n✨ Sesión finalizada. Se han sincronizado {count} ejercicios.")
    remaining = Exercise.objects.filter(is_global=True).exclude(gif_url__icontains="cloudinary").count()
    print(f"📊 Quedan {remaining} ejercicios por migrar.")

if __name__ == "__main__":
    sync_gifs()
