import 'package:flutter/material.dart';

import 'body_measure_model.dart';

/// Serie temporal de una métrica corporal asociada a un grupo muscular.
class MeasureSeriesPoint {
  final DateTime date;
  final double valueCm;
  final int entryId;

  const MeasureSeriesPoint({
    required this.date,
    required this.valueCm,
    required this.entryId,
  });
}

class MuscleGroupMetric {
  final String id;
  final String label;
  final IconData icon;
  final Color color;
  final List<MeasureSeriesPoint> points;

  const MuscleGroupMetric({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.points,
  });

  bool get hasData => points.length >= 2;

  double? get firstValue => points.isNotEmpty ? points.first.valueCm : null;

  double? get lastValue => points.isNotEmpty ? points.last.valueCm : null;

  double? get deltaCm {
    if (firstValue == null || lastValue == null || points.length < 2) return null;
    return lastValue! - firstValue!;
  }
}

/// Mapea registros de medidas a grupos musculares / zonas corporales.
class MuscleGroupMetricsBuilder {
  static const _palette = [
    Color(0xFFE2F163),
    Color(0xFF6EC1E4),
    Color(0xFFFF8A65),
    Color(0xFFBA68C8),
    Color(0xFF4DB6AC),
    Color(0xFFFFD54F),
    Color(0xFF90CAF9),
    Color(0xFFAED581),
  ];

  static List<MuscleGroupMetric> fromEntries(List<BodyMeasureEntry> entries) {
    final sorted = [...entries]..sort(compareBodyMeasureEntriesAsc);

    final groups = <MuscleGroupMetric>[
      _series(
        id: 'chest',
        label: 'Pecho',
        icon: Icons.fitness_center,
        colorIndex: 0,
        sorted: sorted,
        value: (e) => e.chestCm,
      ),
      _series(
        id: 'shoulders',
        label: 'Hombros',
        icon: Icons.accessibility_new,
        colorIndex: 1,
        sorted: sorted,
        value: (e) => e.shouldersCm,
      ),
      _series(
        id: 'biceps_left',
        label: 'Brazo izquierdo',
        icon: Icons.sports_gymnastics,
        colorIndex: 2,
        sorted: sorted,
        value: (e) => e.bicepLeftCm,
      ),
      _series(
        id: 'biceps_right',
        label: 'Brazo derecho',
        icon: Icons.sports_gymnastics,
        colorIndex: 3,
        sorted: sorted,
        value: (e) => e.bicepRightCm,
      ),
      _series(
        id: 'thigh_left',
        label: 'Muslo izquierdo',
        icon: Icons.directions_run,
        colorIndex: 4,
        sorted: sorted,
        value: (e) => e.thighLeftCm,
      ),
      _series(
        id: 'thigh_right',
        label: 'Muslo derecho',
        icon: Icons.directions_run,
        colorIndex: 5,
        sorted: sorted,
        value: (e) => e.thighRightCm,
      ),
      _series(
        id: 'hips',
        label: 'Cadera / glúteos',
        icon: Icons.self_improvement,
        colorIndex: 6,
        sorted: sorted,
        value: (e) => e.hipsCm,
      ),
      _series(
        id: 'waist',
        label: 'Cintura',
        icon: Icons.straighten,
        colorIndex: 7,
        sorted: sorted,
        value: (e) => e.waistCm,
      ),
      _series(
        id: 'neck',
        label: 'Cuello',
        icon: Icons.face_retouching_natural,
        colorIndex: 0,
        sorted: sorted,
        value: (e) => e.neckCm,
      ),
    ];

    return groups.where((g) => g.points.isNotEmpty).toList();
  }

  static MuscleGroupMetric _series({
    required String id,
    required String label,
    required IconData icon,
    required int colorIndex,
    required List<BodyMeasureEntry> sorted,
    required double? Function(BodyMeasureEntry) value,
  }) {
    final points = <MeasureSeriesPoint>[];
    for (final entry in sorted) {
      final v = value(entry);
      if (v != null) {
        points.add(
          MeasureSeriesPoint(date: entry.date, valueCm: v, entryId: entry.id),
        );
      }
    }
    return MuscleGroupMetric(
      id: id,
      label: label,
      icon: icon,
      color: _palette[colorIndex % _palette.length],
      points: points,
    );
  }
}
