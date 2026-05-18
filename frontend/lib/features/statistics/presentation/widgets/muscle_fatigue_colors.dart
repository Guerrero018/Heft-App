import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/muscle_map_config.dart';
import 'muscle_svg_mapping.dart';

/// Sin fatiga: se conserva el gris original del SVG (`defaultColor`).
const kMuscleFatigueLow = Color(0xFFF2E8B8);
const kMuscleFatigueMid = Color(0xFFE6D14D);
const kMuscleFatigueHigh = Color(0xFFD4A017);

Color muscleFatigueFillColor(double load, {required Color defaultColor}) {
  if (load <= 0) return defaultColor;
  if (load < 0.34) return kMuscleFatigueLow;
  if (load < 0.67) return kMuscleFatigueMid;
  return kMuscleFatigueHigh;
}

/// Compatibilidad con leyenda / selección (sin color base del SVG).
Color muscleFatigueLegendColor(double load) {
  if (load <= 0) return const Color(0xFFBDBDBD);
  return muscleFatigueFillColor(load, defaultColor: const Color(0xFFBDBDBD));
}

/// Solo devuelve carga si ese grupo tiene volumen en la semana (sin rellenar
/// desde otros músculos: el mapa anatómico es más fino que los grupos de la BD).
double resolveMuscleLoad(String key, Map<String, double> loads) {
  if (!isSupportedMuscleMapKey(key)) return 0;
  return loads[key] ?? 0;
}

/// Colorea paths del SVG según fatiga semanal (ids anatómicos → claves Heft).
class MuscleFatigueColorMapper extends ColorMapper {
  const MuscleFatigueColorMapper({
    required this.loads,
    required this.isFront,
  });

  final Map<String, double> loads;
  final bool isFront;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (attributeName != 'fill' || id == null) return color;
    if (svgPathIdIsDecorative(id)) return color;

    final key = svgPathIdToMuscleKey(id, isFront: isFront);
    if (key == null) return color;

    final load = resolveMuscleLoad(key, loads);
    return muscleFatigueFillColor(load, defaultColor: color);
  }
}
