import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/presentation/widgets/body_silhouette_paths.dart';
import 'package:frontend/features/statistics/presentation/widgets/muscle_map_paths.dart';
import 'package:path_drawing/path_drawing.dart';

void main() {
  test('body silhouette SVG paths parse', () {
    for (final data in [frontSilhouettePath, backSilhouettePath]) {
      expect(() => parseSvgPathData(data), returnsNormally);
    }
  });

  test('all muscle map SVG paths parse', () {
    final paths = <String>[
      ...frontMusclePaths.map((m) => m.pathData),
      ...backMusclePaths.map((m) => m.pathData),
    ];

    for (var i = 0; i < paths.length; i++) {
      expect(
        () => parseSvgPathData(paths[i]),
        returnsNormally,
        reason: 'path index $i: ${paths[i].substring(0, 40)}...',
      );
    }
  });
}
