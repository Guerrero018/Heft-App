import os
import json
import time
import google.generativeai as genai
from dotenv import load_dotenv

# Cargar variables de entorno desde el raíz
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(os.path.dirname(BASE_DIR), ".env"))

# --- CONFIGURACIÓN ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
INPUT_FILE = os.path.join(BASE_DIR, "exercises_data.json")
OUTPUT_FILE = os.path.join(BASE_DIR, "exercises_data_es.json")

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel('gemini-flash-latest')

# --- MAPEOS LOCALES (ESTABLECIDOS PREVIAMENTE) ---
MUSCLE_MAPPING = {
    'back': 'espalda', 'cardio': 'cardio', 'chest': 'pecho', 'lower arms': 'antebrazos',
    'lower legs': 'gemelos', 'neck': 'trapecios', 'shoulders': 'hombros',
    'upper arms': 'biceps', 'upper legs': 'cuadriceps', 'waist': 'abdominales'
}

EQUIPMENT_TRANSLATION = {
    'barbell': 'Barra', 'dumbbell': 'Mancuernas', 'body weight': 'Peso corporal',
    'cable': 'Polea', 'kettlebell': 'Pesa rusa', 'machine': 'Máquina', 'smith machine': 'Máquina Smith',
    'medicine ball': 'Balón medicinal', 'resistance band': 'Banda de resistencia',
    'stability ball': 'Pelota de estabilidad', 'ez barbell': 'Barra EZ', 'rope': 'Cuerda', 'bench': 'Banco'
}

DIFFICULTY_MAPPING = {
    'beginner': 'Principiante', 'intermediate': 'Intermedio', 'advanced': 'Avanzado'
}

def translate_batch(batch):
    while True:
        prompt = f"""
        Eres un experto en fitness. Traduce este JSON al ESPAÑOL. 
        Traduce los campos:
        - name
        - instructions (lista de frases)
        - description
        - category
        - secondaryMuscles (traduce los nombres de los músculos a español)
        
        Mantén el 'id' intacto.
        JSON: {json.dumps(batch)}
        """
        try:
            response = model.generate_content(
                prompt,
                generation_config=genai.types.GenerationConfig(
                    response_mime_type="application/json",
                )
            )
            
            # Limpieza robusta del JSON (Eliminar comas colgantes y espacios extra)
            import re
            text = response.text.strip()
            # Eliminar comas seguidas de un cierre de array o objeto: ,] o ,}
            text = re.sub(r',\s*([\]}])', r'\1', text)
            
            data = json.loads(text)
            if data:
                return data
            raise Exception("Respuesta vacía")
        except Exception as e:
            if "429" in str(e) or "RESOURCE_EXHAUSTED" in str(e):
                print(f"   [!] Límite alcanzado. Esperando 60s...")
                time.sleep(60)
            else:
                print(f"   [!] Error: {e}. Reintentando en 15s...")
                time.sleep(15)
            continue

def translate_all():
    if not os.path.exists(INPUT_FILE):
        print(f"❌ Error: No se encuentra {INPUT_FILE}")
        return

    with open(INPUT_FILE, "r", encoding="utf-8") as f:
        all_raw = json.load(f)

    translated_dict = {}
    if os.path.exists(OUTPUT_FILE):
        try:
            with open(OUTPUT_FILE, "r", encoding="utf-8") as f:
                prev_data = json.load(f)
                translated_dict = {str(item['id']): item for item in prev_data}
                print(f"   📂 Reanudando: {len(translated_dict)}/{len(all_raw)} ya traducidos.")
        except:
            pass

    # Lote maximizado para reducir peticiones (Aprox. 33 peticiones para todo el dataset)
    batch_size = 40
    pending = [ex for ex in all_raw if str(ex['id']) not in translated_dict]
    
    if not pending:
        print("✅ Todo traducido.")
        return

    print(f"🚀 Traduciendo {len(pending)} ejercicios (Mapeos locales + IA)...")

    for i in range(0, len(pending), batch_size):
        chunk = pending[i:i+batch_size]
        
        # Filtramos solo lo que la IA DEBE traducir
        to_translate = []
        for x in chunk:
            to_translate.append({
                "id": x['id'],
                "name": x['name'],
                "secondaryMuscles": x.get('secondaryMuscles', []),
                "instructions": x.get('instructions', []),
                "description": x.get('description', ''),
                "category": x.get('category', '')
            })
        
        results = translate_batch(to_translate)
        results_map = {str(r['id']): r for r in results}
        
        for original in chunk:
            id_str = str(original['id'])
            if id_str in results_map:
                translated_item = original.copy()
                
                # 1. Aplicar traducciones de la IA
                translated_item.update(results_map[id_str])
                
                # 2. Aplicar MAPEOS LOCALES (Sin IA)
                bp = original.get('bodyPart', '').lower()
                translated_item['bodyPart_es'] = MUSCLE_MAPPING.get(bp, bp.capitalize())
                
                eq = original.get('equipment', '').lower()
                translated_item['equipment_es'] = EQUIPMENT_TRANSLATION.get(eq, eq.capitalize())
                
                diff = original.get('difficulty', '').lower()
                translated_item['difficulty_es'] = DIFFICULTY_MAPPING.get(diff, diff.capitalize())

                translated_dict[id_str] = translated_item

        with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
            json.dump(list(translated_dict.values()), f, indent=4, ensure_ascii=False)
            
        print(f"   ✅ Procesado bloque {i//batch_size + 1} ({len(translated_dict)}/{len(all_raw)})")
        time.sleep(3)

    print(f"\n🎉 ¡TRADUCCIÓN COMPLETA! Archivo: {OUTPUT_FILE}")

if __name__ == "__main__":
    translate_all()
