import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'anatomy_silhouette_view.dart';
import 'muscle_fatigue_colors.dart';
import 'muscle_map_paths.dart';

/// Si true, solo silueta sin colorear por fatiga (depuración).
const kMuscleMapSilhouetteOnly = false;

class InteractiveMuscleMap extends StatefulWidget {
  final Map<String, double> frontLoads;
  final Map<String, double> backLoads;
  /// Volumen en kg por clave del mapa (esta semana).
  final Map<String, double> absoluteKgByMapKey;

  const InteractiveMuscleMap({
    super.key,
    required this.frontLoads,
    required this.backLoads,
    this.absoluteKgByMapKey = const {},
  });

  @override
  State<InteractiveMuscleMap> createState() => _InteractiveMuscleMapState();
}

class _InteractiveMuscleMapState extends State<InteractiveMuscleMap> {
  String? _selectedZoneId;
  String? _selectedLabel;
  double _selectedLoad = 0;
  double _selectedAbsoluteKg = 0;

  List<_HitZone> _hitZones(Size size) {
    if (kMuscleMapSilhouetteOnly) return const [];

    final gap = size.width * 0.04;
    final padH = size.width * 0.08;
    final bodyW = (size.width - gap - padH * 2) / 2;
    final top = 28.0;
    final bodyH = size.height - top - 8;
    final frontRect = Rect.fromLTWH(padH, top, bodyW, bodyH);
    final backRect = Rect.fromLTWH(padH + bodyW + gap, top, bodyW, bodyH);

    final hits = <_HitZone>[];
    for (final m in frontMusclePaths) {
      hits.add(_HitZone(
        id: m.id,
        label: m.label,
        path: m.pathInRect(frontRect),
        zone: m,
        loads: widget.frontLoads,
      ));
    }
    for (final m in backMusclePaths) {
      hits.add(_HitZone(
        id: m.id,
        label: m.label,
        path: m.pathInRect(backRect),
        zone: m,
        loads: widget.backLoads,
      ));
    }
    return hits;
  }

  void _handleTap(Offset position, Size size) {
    for (final hit in _hitZones(size).reversed) {
      if (hit.path.contains(position)) {
        final load = _resolveLoad(hit.zone, hit.loads);
        setState(() {
          if (_selectedZoneId == hit.id) {
            _selectedZoneId = null;
            _selectedLabel = null;
            _selectedLoad = 0;
            _selectedAbsoluteKg = 0;
          } else {
            _selectedZoneId = hit.id;
            _selectedLabel =
                hit.label.isNotEmpty ? hit.label : _labelForId(hit.id);
            _selectedLoad = load;
            _selectedAbsoluteKg = _absoluteKgForZone(hit.zone);
          }
        });
        return;
      }
    }
    setState(() {
      _selectedZoneId = null;
      _selectedLabel = null;
      _selectedLoad = 0;
      _selectedAbsoluteKg = 0;
    });
  }

  String _labelForId(String id) {
    final base = id.replaceAll('_r', '');
    for (final m in [...frontMusclePaths, ...backMusclePaths]) {
      if (m.id == base || m.id == id) return m.label;
    }
    return base;
  }

  double _resolveLoad(MusclePathDef zone, Map<String, double> loads) {
    final base = zone.id.replaceAll('_r', '');
    return resolveMuscleLoad(
      loads.containsKey(zone.id) ? zone.id : base,
      loads,
    );
  }

  String _loadLabel(double load) {
    if (load <= 0) return 'Sin carga esta semana';
    if (load < 0.34) return 'Carga baja';
    if (load < 0.67) return 'Carga media';
    return 'Carga alta';
  }

  String _formatKg(double kg) {
    if (kg >= 1000) return '${(kg / 1000).toStringAsFixed(1)}k kg';
    return '${kg.round()} kg';
  }

  double _absoluteKgForZone(MusclePathDef zone) {
    final base = zone.id.replaceAll('_r', '');
    return widget.absoluteKgByMapKey[zone.id] ??
        widget.absoluteKgByMapKey[base] ??
        0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapHeight = constraints.maxWidth * 1.15;
                if (kMuscleMapSilhouetteOnly) {
                  return AnatomySilhouetteView(
                    width: constraints.maxWidth,
                    frontLoads: const {},
                    backLoads: const {},
                  );
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (d) => _handleTap(
                    d.localPosition,
                    Size(constraints.maxWidth, mapHeight),
                  ),
                  child: AnatomySilhouetteView(
                    width: constraints.maxWidth,
                    frontLoads: widget.frontLoads,
                    backLoads: widget.backLoads,
                  ),
                );
              },
            ),
          ),
        ),
        if (_selectedLabel != null && _selectedLabel!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: muscleFatigueLegendColor(_selectedLoad),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedLabel!,
                    style: const TextStyle(
                      color: AppTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _loadLabel(_selectedLoad),
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                    if (_selectedAbsoluteKg > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatKg(_selectedAbsoluteKg),
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          const Text(
            'Toca un músculo para ver el volumen de esta semana',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _HitZone {
  final String id;
  final String label;
  final Path path;
  final MusclePathDef zone;
  final Map<String, double> loads;

  _HitZone({
    required this.id,
    required this.label,
    required this.path,
    required this.zone,
    required this.loads,
  });
}

class _AnatomyMuscleMapPainter extends CustomPainter {
  final Map<String, double> frontLoads;
  final Map<String, double> backLoads;
  final String? selectedZoneId;

  _AnatomyMuscleMapPainter({
    required this.frontLoads,
    required this.backLoads,
    required this.selectedZoneId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF141414),
    );

    final gap = size.width * 0.04;
    final padH = size.width * 0.08;
    final bodyW = (size.width - gap - padH * 2) / 2;
    final top = 28.0;
    final bodyH = size.height - top - 8;
    final frontRect = Rect.fromLTWH(padH, top, bodyW, bodyH);
    final backRect = Rect.fromLTWH(padH + bodyW + gap, top, bodyW, bodyH);

    _paintFigure(
      canvas,
      rect: frontRect,
      muscles: frontMusclePaths,
      loads: frontLoads,
      title: 'FRONTAL',
    );
    _paintFigure(
      canvas,
      rect: backRect,
      muscles: backMusclePaths,
      loads: backLoads,
      title: 'POSTERIOR',
    );
  }

  void _paintFigure(
    Canvas canvas, {
    required Rect rect,
    required List<MusclePathDef> muscles,
    required Map<String, double> loads,
    required String title,
  }) {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    titlePainter.paint(
      canvas,
      Offset(rect.center.dx - titlePainter.width / 2, 8),
    );

    final silhouette = bodyOutlinePath(
      rect,
      isFront: title == 'FRONTAL',
    );

    canvas.drawPath(
      silhouette,
      Paint()..color = const Color(0xFF2A3038),
    );

    if (kMuscleMapSilhouetteOnly) {
      canvas.drawPath(
        silhouette,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Colors.white.withValues(alpha: 0.55)
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    for (final muscle in muscles) {
      final load = _resolveLoad(muscle, loads);
      final path = muscle.pathInRect(rect);
      final fill = muscleFatigueLegendColor(load);
      final selected = selectedZoneId == muscle.id;

      canvas.drawPath(
        path,
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = selected
              ? AppTheme.primaryColor
              : Colors.white.withValues(alpha: 0.12)
          ..strokeWidth = selected ? 2.2 : 0.9,
      );

      if (muscle.label.isNotEmpty) {
        _drawLabel(canvas, muscle, rect, load);
      }
    }

    canvas.drawPath(
      silhouette,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.white.withValues(alpha: 0.14)
        ..strokeWidth = 1.4,
    );
  }

  double _resolveLoad(MusclePathDef zone, Map<String, double> loads) {
    final base = zone.id.replaceAll('_r', '');
    return resolveMuscleLoad(
      loads.containsKey(zone.id) ? zone.id : base,
      loads,
    );
  }

  void _drawLabel(
    Canvas canvas,
    MusclePathDef muscle,
    Rect bodyRect,
    double load,
  ) {
    final anchor = muscle.anchorInRect(bodyRect);
    final style = TextStyle(
      color: load > 0
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.white.withValues(alpha: 0.45),
      fontSize: 9.5,
      fontWeight: load > 0 ? FontWeight.w600 : FontWeight.w400,
    );

    final tp = TextPainter(
      text: TextSpan(text: muscle.label, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    final labelX = muscle.labelOnLeft
        ? (bodyRect.left - tp.width - 14).clamp(4.0, bodyRect.right)
        : bodyRect.right + 14;
    final labelOffset = Offset(labelX, anchor.dy - tp.height / 2);

    final lineEnd = Offset(
      muscle.labelOnLeft ? labelOffset.dx + tp.width : labelOffset.dx,
      labelOffset.dy + tp.height / 2,
    );

    canvas.drawLine(
      anchor,
      lineEnd,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..strokeWidth = 0.7,
    );
    tp.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant _AnatomyMuscleMapPainter oldDelegate) {
    return oldDelegate.frontLoads != frontLoads ||
        oldDelegate.backLoads != backLoads ||
        oldDelegate.selectedZoneId != selectedZoneId;
  }
}
