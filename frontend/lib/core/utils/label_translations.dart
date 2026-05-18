/// Traducciones de etiquetas mostradas en la UI (valores del API en inglés o español).
String translateMuscleGroup(String muscle) {
  const translations = {
    'chest': 'Pecho',
    'pecho': 'Pecho',
    'back': 'Espalda',
    'espalda': 'Espalda',
    'shoulders': 'Hombros',
    'hombros': 'Hombros',
    'biceps': 'Bíceps',
    'triceps': 'Tríceps',
    'quadriceps': 'Cuádriceps',
    'cuadriceps': 'Cuádriceps',
    'hamstrings': 'Isquios',
    'isquiotibiales': 'Femoral',
    'glutes': 'Glúteos',
    'gluteos': 'Glúteos',
    'calves': 'Gemelos',
    'gemelos': 'Gemelos',
    'abs': 'Abs',
    'abdominales': 'Abs',
    'cardio': 'Cardio',
  };
  return translations[muscle.toLowerCase()] ?? muscle.replaceAll('_', ' ');
}

String translateEquipmentType(String type) {
  const translations = {
    'barra': 'Barra',
    'barbell': 'Barra',
    'mancuernas': 'Mancuernas',
    'dumbbell': 'Mancuernas',
    'dumbbells': 'Mancuernas',
    'maquina': 'Máquina',
    'machine': 'Máquina',
    'polea': 'Polea',
    'cable': 'Polea',
    'peso_corporal': 'Peso corporal',
    'bodyweight': 'Peso corporal',
    'pesa_rusa': 'Pesa rusa',
    'kettlebell': 'Pesa rusa',
    'maquina_smith': 'Máquina Smith',
    'smith_machine': 'Máquina Smith',
    'otro': 'Otro',
    'other': 'Otro',
  };
  return translations[type.toLowerCase()] ?? type.replaceAll('_', ' ');
}
