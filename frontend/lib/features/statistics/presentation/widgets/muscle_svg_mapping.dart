import '../../domain/muscle_map_config.dart';

/// Mapeo de ids de path en muscle_layer_*.svg → claves del mapa Heft.
///
/// El SVG (flutter-body-atlas) nombra músculos anatómicos concretos; la app
/// solo registra volumen por [kAppMuscleGroupsDb]. Cada regla agrupa varios
/// paths en un grupo general. Paths sin regla quedan en gris (sin fatiga).

const _decorPrefixes = <String>[
  'underlayer',
  'foot_',
  'hand_',
  'ankle_',
  'wrist_',
  'palm_',
  'platysma',
  'sternohyoid',
  // Cabeza / cuello estético (no hay grupo en catálogo de ejercicios)
  'sternocleidomastoid',
];

bool svgPathIdIsDecorative(String id) {
  for (final p in _decorPrefixes) {
    if (id == p || id.startsWith(p)) return true;
  }
  return false;
}

/// Reglas por prefijo (orden: la primera coincidencia gana).
const _frontPrefixRules = <(String, String)>[
  ('pectoralis', 'chest'),
  ('anterior_deltoid', 'shoulders'),
  ('lateral_deltoid', 'shoulders'),
  ('trapezius_upper', 'traps'),
  ('rectus_abdominis', 'abs'),
  ('external_oblique', 'abs'),
  ('biceps_brachii', 'biceps'),
  ('triceps_brachii', 'triceps'),
  ('brachioradialis', 'forearms'),
  ('flexor_digitorum', 'forearms'),
  ('flexor_carpi', 'forearms'),
  ('extensor_carpi', 'forearms'),
  ('palmaris_longus', 'forearms'),
  ('pronator', 'forearms'),
  ('latissimus_dorsi', 'back'),
  ('rectus_femoris', 'quads'),
  ('vastus_', 'quads'),
  ('sartoris', 'quads'),
  ('iliotibial', 'quads'),
  ('gracilis', 'adductors'),
  ('adductor_longus', 'adductors'),
  ('pectineus', 'adductors'),
  ('gluteus_medius_2', 'hip_abductors'),
  ('gastrocnemius', 'calves'),
  ('semitendinosus', 'hamstrings'),
  ('tibialis', 'calves'),
];

const _backPrefixRules = <(String, String)>[
  ('latissimus_dorsi', 'back'),
  ('infraspinatus', 'back'),
  ('trapezius', 'traps'),
  ('posterior_deltoid', 'shoulders'),
  ('lateral_deltoid', 'shoulders'),
  ('triceps_brachii', 'triceps'),
  ('biceps_femoris', 'hamstrings'),
  ('semitendinosus', 'hamstrings'),
  ('semimembranosus', 'hamstrings'),
  ('gluteus_maximus', 'glutes'),
  ('gluteus_medius', 'glutes'),
  ('gastrocnemius', 'calves'),
  ('adductor_magnus', 'adductors'),
  ('external_oblique', 'abs'),
  ('iliotibial', 'quads'),
  ('brachioradialis', 'forearms'),
  ('extensor_digitorum', 'forearms'),
  ('extensor_carpi', 'forearms'),
  ('flexor_carpi', 'forearms'),
  ('anconeus', 'forearms'),
];

String? svgPathIdToMuscleKey(String id, {required bool isFront}) {
  if (svgPathIdIsDecorative(id)) return null;

  final rules = isFront ? _frontPrefixRules : _backPrefixRules;
  for (final (prefix, key) in rules) {
    if (!id.startsWith(prefix)) continue;
    if (isSupportedMuscleMapKey(key)) return key;
  }
  return null;
}

/// @deprecated Usar [muscleMapKeyLabel] en muscle_map_config.dart.
String muscleKeyLabel(String key) => muscleMapKeyLabel(key);
