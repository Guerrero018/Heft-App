/// Grupos musculares de la app (BD / `Exercise.muscle_group`) y su vista en el mapa.
///
/// Solo estos grupos reciben volumen de entrenamientos. El SVG anatómico es más
/// detallado; cada path se agrupa en una de estas claves generales.

/// Claves `muscle_group` en español (backend `MUSCLE_GROUPS`).
const kAppMuscleGroupsDb = [
  'pecho',
  'espalda',
  'hombros',
  'trapecios',
  'cuadriceps',
  'isquiotibiales',
  'gemelos',
  'gluteos',
  'aductores',
  'abductores',
  'biceps',
  'triceps',
  'antebrazos',
  'abdominales',
  'espalda_baja',
  'cardio',
  'otros',
];

/// BD → (clave mapa, `front` | `back`).
const kDbToMuscleMapKey = <String, (String mapKey, String view)>{
  'pecho': ('chest', 'front'),
  'abdominales': ('abs', 'front'),
  'espalda_baja': ('abs', 'front'),
  'cuadriceps': ('quads', 'front'),
  'hombros': ('shoulders', 'front'),
  'trapecios': ('traps', 'back'),
  'biceps': ('biceps', 'front'),
  'espalda': ('back', 'back'),
  'triceps': ('triceps', 'back'),
  'gluteos': ('glutes', 'back'),
  'isquiotibiales': ('hamstrings', 'back'),
  'gemelos': ('calves', 'back'),
  'aductores': ('adductors', 'front'),
  'abductores': ('hip_abductors', 'front'),
  'antebrazos': ('forearms', 'front'),
  'cardio': ('abs', 'front'),
  'otros': ('abs', 'front'),
};

/// Claves del mapa que pueden recibir color por fatiga (derivadas de la BD).
const kSupportedMuscleMapKeys = {
  'chest',
  'abs',
  'quads',
  'shoulders',
  'traps',
  'biceps',
  'back',
  'triceps',
  'glutes',
  'hamstrings',
  'calves',
  'adductors',
  'hip_abductors',
  'forearms',
};

bool isSupportedMuscleMapKey(String key) =>
    kSupportedMuscleMapKeys.contains(key);

/// Etiqueta en español para UI del mapa.
String muscleMapKeyLabel(String key) {
  const labels = {
    'chest': 'Pecho',
    'abs': 'Abdominales',
    'quads': 'Cuádriceps',
    'shoulders': 'Hombros',
    'traps': 'Trapecios',
    'biceps': 'Bíceps',
    'back': 'Espalda',
    'triceps': 'Tríceps',
    'glutes': 'Glúteos',
    'hamstrings': 'Isquiotibiales',
    'calves': 'Gemelos',
    'adductors': 'Aductores',
    'hip_abductors': 'Abductores',
    'forearms': 'Antebrazos',
  };
  return labels[key] ?? key;
}
