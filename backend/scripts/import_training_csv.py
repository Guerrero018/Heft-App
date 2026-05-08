import os
import csv
import django
import sys
import re
from datetime import datetime, timedelta

# Configurar el entorno de Django
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'heft_core.settings')
django.setup()

from apps.workouts.models import WorkoutSession, WorkoutSet
from apps.exercises.models import Exercise
from apps.routines.models import Routine
from django.contrib.auth import get_user_model

User = get_user_model()

def parse_weight(weight_str):
    if not weight_str or str(weight_str).strip() == '':
        return None
    weight_str = str(weight_str).lower().replace(',', '.')
    
    # Manejar "30+barra z" o "30 + barra z" -> Solo 30
    if '+barra z' in weight_str or '+ barra z' in weight_str:
        val = weight_str.replace('+barra z', '').replace('+ barra z', '').strip()
        try:
            return float(val)
        except:
            return 0.0
            
    # Manejar rangos o dropsets "63 - 54.5" -> Solo 63
    if '-' in weight_str:
        try:
            return float(weight_str.split('-')[0].strip())
        except:
            pass
            
    try:
        match = re.search(r"(\d+\.?\d*)", weight_str)
        if match:
            return float(match.group(1))
    except:
        pass
        
    try:
        return float(weight_str.strip())
    except:
        return None

def parse_reps(reps_str):
    if not reps_str or str(reps_str).strip() == '':
        return None
    reps_str = str(reps_str).lower()
    
    if '-' in reps_str:
        try:
            return int(reps_str.split('-')[0].strip())
        except:
            pass
            
    try:
        match = re.search(r"(\d+)", reps_str)
        if match:
            return int(match.group(1))
    except:
        pass
        
    try:
        return int(reps_str.strip())
    except:
        return None

def import_csv(file_path, username):
    try:
        user = User.objects.get(username=username)
    except User.DoesNotExist:
        print(f"Error: El usuario {username} no existe.")
        return

    print(f"Borrando sesiones anteriores de {username}...")
    WorkoutSession.objects.filter(user=user).delete()

    print(f"Iniciando importación para el usuario: {username}")
    
    if not os.path.exists(file_path):
        potential_path = os.path.join('..', file_path)
        if os.path.exists(potential_path):
            file_path = potential_path
            
    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.reader(f)
        rows = list(reader)

    weeks = []
    current_week = None
    current_session = None
    
    # 1. Agrupar datos por semanas y sesiones
    for row in rows:
        if not row or all(not cell.strip() for cell in row):
            continue
            
        first_cell = row[0].strip()
        
        if first_cell.startswith('Semana'):
            current_week = {'name': first_cell, 'sessions': []}
            weeks.append(current_week)
            current_session = None
            continue
            
        if current_week is None:
            continue
            
        if first_cell == 'Grupo muscular' or first_cell == '':
            if current_session and len(row) > 1 and row[1].strip():
                pass 
            else:
                continue
        
        muscle_group = row[0].strip()
        exercise_name = row[1].strip()
        
        if not exercise_name:
            continue
            
        if muscle_group:
            mg_lower = muscle_group.lower()
            routine_name = "Workout"
            if "pecho" in mg_lower and "triceps" in mg_lower:
                routine_name = "Push"
            elif "espalda" in mg_lower and "biceps" in mg_lower:
                routine_name = "Pull"
            elif "pierna" in mg_lower:
                routine_name = "Leg"
            elif "pecho" in mg_lower and "espalda" in mg_lower:
                routine_name = "ChestBack"
            elif "brazo" in mg_lower or "hombro" in mg_lower:
                routine_name = "Arm"
                
            current_session = {
                'name': f"{routine_name} - {current_week['name']}",
                'exercises': []
            }
            current_week['sessions'].append(current_session)
            
        if current_session:
            sets = []
            for i in range(2, 10, 2): 
                if i+1 < len(row):
                    w = parse_weight(row[i])
                    r = parse_reps(row[i+1])
                    if w is not None and r is not None:
                        sets.append({'weight': w, 'reps': r})
            
            if sets:
                current_session['exercises'].append({
                    'name': exercise_name,
                    'sets': sets
                })

    # 2. Mapeo de Ejercicios
    EXERCISE_MAPPING = {
        'press banca': 'press de banca con barra',
        'remo con barra': 'remo con barra inclinado',
        'prensa': 'Prensa de piernas en trineo a 45°',
        'extensión cuadriceps': 'extensión de piernas',
        'femoral tumbado': 'curl de isquiotibiales',
        'gemelo': 'Elevación de talones en prensa de piernas sentado',
        'jalón agarre abierto': 'Jalón al pecho con cable',
        'delt. posterior polea': 'Apertura inversa alta cruzada de pie con cable',
        'curl detras hombro polea': 'Curl de bíceps por detras del hombro en polea',
        'hammer': 'Press de pecho en máquina de palanca',
        'extensión con barra': 'Extensión de tríceps en polea (barra en v)',
        'extensión de tríceps': 'Extensión de tríceps en polea (barra en v)',
        'extensión unilateral': 'Extensión de tríceps en polea (barra en v)',
        'jalón agarre cerrado': 'Jalón al pecho cerrado con cable',
        'pullover': 'Pullover de pie en polea',
        'remo polea unilateral': 'Remo alterno a una mano sentado con cable',
        'remo polea abierto': 'Remo sentado con agarre ancho con cable',
        'sentadilla multipower': 'Sentadilla de silla en máquina smith',
        'press inclinado multipower': 'Press de banca inclinado en máquina smith',
        'elevación lateral polea': 'Elevación lateral a una mano con cable',
        'curl barra z': 'curl de bíceps con barra',
        'peck deck': 'peck deck',
        'remo t': 'remo en barra t',
        'sentadilla': 'sentadilla',
        'press inclinado': 'press de banca inclinado',
        'adductor': 'Aducción de cadera sentado en máquina de palanca',
        'aductores': 'Aducción de cadera sentado en máquina de palanca',
    }

    # 3. Guardar en DB trabajando HACIA ATRÁS
    all_sessions = []
    for w in weeks:
        for s in w['sessions']:
            if s['exercises']:
                all_sessions.append(s)
                
    total_count = len(all_sessions)
    print(f"Total sesiones a importar: {total_count}")
    
    current_date = datetime.now().date()
    
    total_sessions_created = 0
    total_sets_created = 0

    # Iterar sesiones de la última a la primera
    for i, session_data in enumerate(reversed(all_sessions)):
        session = WorkoutSession.objects.create(
            user=user,
            name=session_data['name'],
            is_completed=True,
            notes=f"Importado automáticamente de CSV"
        )
        
        session.start_time = datetime.combine(current_date, datetime.min.time()) + timedelta(hours=18) # 6:00 PM
        session.date = current_date
        session.save()
        WorkoutSession.objects.filter(id=session.id).update(date=current_date)
        
        for exercise_data in session_data['exercises']:
            name_to_search = exercise_data['name'].lower()
            
            # Diferenciación especial para Press Francés
            if 'press francés' in name_to_search or 'press frances' in name_to_search:
                if 'mancuerna' in name_to_search:
                    search_term = 'press francés con mancuernas'
                else:
                    search_term = 'press francés con barra'
            else:
                mapped_name = None
                for key, val in EXERCISE_MAPPING.items():
                    if key in name_to_search:
                        mapped_name = val
                        break
                search_term = mapped_name if mapped_name else name_to_search
            
            exercise = Exercise.objects.filter(name__icontains=search_term).first()
            
            if not exercise and not mapped_name:
                first_word = search_term.split()[0]
                exercise = Exercise.objects.filter(name__icontains=first_word).first()
            
            if not exercise and mapped_name:
                print(f"Creando nuevo ejercicio: {mapped_name}")
                exercise = Exercise.objects.create(
                    name=mapped_name,
                    muscle_group="aductores" if "adductor" in search_term.lower() else "otros",
                    equipment="polea",
                    difficulty="Intermedio",
                    category="fuerza",
                    is_global=True
                )
            
            if not exercise:
                exercise = Exercise.objects.all().first()
            
            for idx, set_data in enumerate(exercise_data['sets']):
                WorkoutSet.objects.create(
                    workout_session=session,
                    exercise=exercise,
                    set_number=idx + 1,
                    weight=set_data['weight'],
                    reps=set_data['reps'],
                    is_completed=True
                )
                total_sets_created += 1
        
        total_sessions_created += 1
        # Restar un día para la siguiente sesión (en orden inverso)
        # Si queremos más realismo podemos restar 1.5 días de media
        current_date -= timedelta(days=1)
        if i % 5 == 0: # Saltear un día extra cada 5 sesiones (descanso)
            current_date -= timedelta(days=1)

    print(f"Importación FINALIZADA:")
    print(f"- Sesiones creadas: {total_sessions_created}")
    print(f"- Series creadas: {total_sets_created}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python import_training_csv.py <username>")
    else:
        import_csv('Rutina+pesos.csv', sys.argv[1])
