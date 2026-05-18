import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/domain/muscle_map_config.dart';
import 'package:frontend/features/statistics/presentation/widgets/muscle_fatigue_colors.dart';
import 'package:frontend/features/statistics/presentation/widgets/muscle_svg_mapping.dart';

void main() {
  group('svgPathIdToMuscleKey', () {
    test('front pectoralis → chest', () {
      expect(
        svgPathIdToMuscleKey('pectoralis_major_l', isFront: true),
        'chest',
      );
    });

    test('front quads paths', () {
      expect(
        svgPathIdToMuscleKey('rectus_femoris_r', isFront: true),
        'quads',
      );
      expect(
        svgPathIdToMuscleKey('vastus_lateralis_l', isFront: true),
        'quads',
      );
    });

    test('back hamstrings', () {
      expect(
        svgPathIdToMuscleKey('biceps_femoris_l', isFront: false),
        'hamstrings',
      );
    });

    test('decorative ids stay unmapped', () {
      expect(svgPathIdToMuscleKey('foot_l', isFront: true), isNull);
      expect(svgPathIdIsDecorative('hand_r'), isTrue);
    });

    test('trapezius maps to trapecios (traps), not hombros', () {
      expect(
        svgPathIdToMuscleKey('trapezius_upper_l', isFront: true),
        'traps',
      );
      expect(
        svgPathIdToMuscleKey('trapezius_middle_r', isFront: false),
        'traps',
      );
    });

    test('every db muscle maps to a supported map key', () {
      for (final db in kAppMuscleGroupsDb) {
        final entry = kDbToMuscleMapKey[db]!;
        expect(isSupportedMuscleMapKey(entry.$1), isTrue);
      }
    });
  });

  group('resolveMuscleLoad', () {
    test('no cross-muscle fallback', () {
      expect(resolveMuscleLoad('adductors', {'quads': 0.9}), 0);
      expect(resolveMuscleLoad('forearms', {'biceps': 0.8}), 0);
      expect(resolveMuscleLoad('traps', {'shoulders': 0.7}), 0);
    });
  });

  group('muscleFatigueFillColor', () {
    test('zero load keeps SVG default', () {
      const base = Color(0xFFBDBDBD);
      expect(
        muscleFatigueFillColor(0, defaultColor: base),
        base,
      );
    });

    test('tier colors', () {
      const base = Color(0xFFBDBDBD);
      expect(muscleFatigueFillColor(0.2, defaultColor: base), kMuscleFatigueLow);
      expect(muscleFatigueFillColor(0.5, defaultColor: base), kMuscleFatigueMid);
      expect(muscleFatigueFillColor(0.9, defaultColor: base), kMuscleFatigueHigh);
    });
  });
}
