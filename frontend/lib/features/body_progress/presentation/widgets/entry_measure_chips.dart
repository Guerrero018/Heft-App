import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/body_measure_model.dart';

/// Chips compactos con las medidas corporales de un registro.
class EntryMeasureChips extends StatelessWidget {
  final BodyMeasureEntry entry;
  final bool compact;

  const EntryMeasureChips({
    super.key,
    required this.entry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!entry.hasBodyMeasurements) {
      return Text(
        'Sin medidas en este registro',
        style: TextStyle(
          color: AppTheme.hintColor.withValues(alpha: 0.8),
          fontSize: compact ? 11 : 12,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    final chips = <Widget>[];
    void add(String label, double? v) {
      if (v == null) return;
      chips.add(_chip('$label ${v.toStringAsFixed(compact ? 0 : 1)}'));
    }

    add('Cuello', entry.neckCm);
    add('Pecho', entry.chestCm);
    add('Cintura', entry.waistCm);
    add('Cadera', entry.hipsCm);
    add('Hombros', entry.shouldersCm);
    add('B. izq', entry.bicepLeftCm);
    add('B. der', entry.bicepRightCm);
    add('M. izq', entry.thighLeftCm);
    add('M. der', entry.thighRightCm);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        compact ? text : '$text cm',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}
