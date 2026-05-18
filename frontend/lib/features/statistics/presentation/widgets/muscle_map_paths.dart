import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import 'body_silhouette_paths.dart';

/// Tamaño de diseño de cada figura (vista frontal / posterior).
const muscleMapDesignSize = Size(200, 480);

class MusclePathDef {
  final String id;
  final String label;
  final String pathData;
  final Offset labelAnchor;
  final bool labelOnLeft;

  const MusclePathDef({
    required this.id,
    required this.label,
    required this.pathData,
    required this.labelAnchor,
    this.labelOnLeft = true,
  });

  Path pathInRect(Rect rect) {
    final parsed = parseSvgPathData(pathData);
    final scaleX = rect.width / muscleMapDesignSize.width;
    final scaleY = rect.height / muscleMapDesignSize.height;
    final matrix = Matrix4.identity()
      ..translateByDouble(rect.left, rect.top, 0, 1)
      ..scaleByDouble(scaleX, scaleY, 1, 1);
    return parsed.transform(matrix.storage);
  }

  Offset anchorInRect(Rect rect) => Offset(
        rect.left + labelAnchor.dx * rect.width,
        rect.top + labelAnchor.dy * rect.height,
      );
}

/// Bloque abdominal (six-pack).
MusclePathDef _absBlock({
  required String pathData,
  bool showLabel = false,
}) =>
    MusclePathDef(
      id: 'abs',
      label: showLabel ? 'Abdominales' : '',
      labelAnchor: const Offset(0.5, 0.33),
      pathData: pathData,
    );

// Contornos corporales: ver body_silhouette_paths.dart

final frontMusclePaths = <MusclePathDef>[
  MusclePathDef(
    id: 'chest',
    label: 'Pectorales',
    labelAnchor: const Offset(0.28, 0.24),
    pathData:
        'M 68 62 C 76 56 88 54 98 56 C 100 58 100 62 98 68 C 94 76 '
        '86 82 76 84 C 70 84 66 80 64 74 C 62 68 64 64 68 62 Z',
  ),
  MusclePathDef(
    id: 'chest',
    label: '',
    labelAnchor: const Offset(0.72, 0.24),
    labelOnLeft: false,
    pathData:
        'M 132 62 C 124 56 112 54 102 56 C 100 58 100 62 102 68 '
        'C 106 76 114 82 124 84 C 130 84 134 80 136 74 C 138 68 '
        '136 64 132 62 Z',
  ),
  MusclePathDef(
    id: 'shoulders',
    label: 'Deltoides',
    labelAnchor: const Offset(0.18, 0.2),
    pathData:
        'M 58 64 C 50 66 44 74 42 84 C 40 94 44 102 52 106 C 60 108 '
        '66 102 68 92 C 70 80 66 70 62 66 C 60 64 58 64 58 64 Z',
  ),
  MusclePathDef(
    id: 'shoulders',
    label: '',
    labelAnchor: const Offset(0.82, 0.2),
    labelOnLeft: false,
    pathData:
        'M 142 64 C 150 66 156 74 158 84 C 160 94 156 102 148 106 '
        'C 140 108 134 102 132 92 C 130 80 134 70 138 66 C 140 64 '
        '142 64 142 64 Z',
  ),
  _absBlock(
    showLabel: true,
    pathData:
        'M 84 98 C 88 96 94 96 98 98 C 100 102 98 108 94 112 C 90 114 '
        '86 112 84 108 C 82 104 82 100 84 98 Z',
  ),
  _absBlock(
    pathData:
        'M 102 98 C 106 96 112 96 116 98 C 118 102 116 108 112 112 '
        'C 108 114 104 112 102 108 C 100 104 100 100 102 98 Z',
  ),
  _absBlock(
    pathData:
        'M 84 114 C 88 112 94 112 98 114 C 100 118 98 124 94 128 '
        'C 90 130 86 128 84 124 C 82 120 82 116 84 114 Z',
  ),
  _absBlock(
    pathData:
        'M 102 114 C 106 112 112 112 116 114 C 118 118 116 124 112 128 '
        'C 108 130 104 128 102 124 C 100 120 100 116 102 114 Z',
  ),
  _absBlock(
    pathData:
        'M 86 130 C 90 128 96 128 100 130 C 102 134 100 140 96 144 '
        'C 92 146 88 144 86 140 C 84 136 84 132 86 130 Z',
  ),
  _absBlock(
    pathData:
        'M 100 130 C 104 128 110 128 114 130 C 116 134 114 140 110 144 '
        'C 106 146 102 144 100 140 C 98 136 98 132 100 130 Z',
  ),
  MusclePathDef(
    id: 'obliques',
    label: 'Oblicuos',
    labelAnchor: const Offset(0.22, 0.36),
    pathData:
        'M 72 108 C 66 112 62 122 60 134 C 58 144 62 152 68 154 '
        'C 74 152 78 142 80 128 C 82 116 78 108 72 108 Z',
  ),
  MusclePathDef(
    id: 'obliques',
    label: '',
    labelAnchor: const Offset(0.78, 0.36),
    labelOnLeft: false,
    pathData:
        'M 128 108 C 134 112 138 122 140 134 C 142 144 138 152 132 154 '
        'C 126 152 122 142 120 128 C 118 116 122 108 128 108 Z',
  ),
  MusclePathDef(
    id: 'biceps',
    label: 'Bíceps',
    labelAnchor: const Offset(0.12, 0.32),
    pathData:
        'M 46 92 C 40 98 36 110 34 126 C 32 140 36 152 44 158 '
        'C 52 162 60 156 64 142 C 66 126 64 110 58 98 C 52 92 48 92 46 92 Z',
  ),
  MusclePathDef(
    id: 'biceps',
    label: '',
    labelAnchor: const Offset(0.88, 0.32),
    labelOnLeft: false,
    pathData:
        'M 154 92 C 160 98 164 110 166 126 C 168 140 164 152 156 158 '
        'C 148 162 140 156 136 142 C 134 126 136 110 142 98 C 148 92 '
        '152 94 154 92 Z',
  ),
  MusclePathDef(
    id: 'forearms',
    label: 'Antebrazos',
    labelAnchor: const Offset(0.1, 0.44),
    pathData:
        'M 40 158 C 34 166 30 182 28 202 C 26 218 30 232 38 238 '
        'C 46 242 54 234 58 216 C 60 196 56 176 48 162 C 44 156 42 158 40 158 Z',
  ),
  MusclePathDef(
    id: 'forearms',
    label: '',
    labelAnchor: const Offset(0.9, 0.44),
    labelOnLeft: false,
    pathData:
        'M 160 158 C 166 166 170 182 172 202 C 174 218 170 232 162 238 '
        'C 154 242 146 234 142 216 C 140 196 144 176 152 162 C 156 156 '
        '158 158 160 158 Z',
  ),
  MusclePathDef(
    id: 'hip_abductors',
    label: 'Abductores',
    labelAnchor: const Offset(0.2, 0.48),
    pathData:
        'M 62 168 C 58 172 56 182 58 192 C 60 200 66 204 72 200 '
        'C 76 194 76 182 72 172 C 68 166 62 168 62 168 Z',
  ),
  MusclePathDef(
    id: 'hip_abductors',
    label: '',
    labelAnchor: const Offset(0.8, 0.48),
    labelOnLeft: false,
    pathData:
        'M 138 168 C 142 172 144 182 142 192 C 140 200 134 204 128 200 '
        'C 124 194 124 182 128 172 C 132 166 138 168 138 168 Z',
  ),
  MusclePathDef(
    id: 'quads',
    label: 'Cuádriceps',
    labelAnchor: const Offset(0.3, 0.58),
    pathData:
        'M 74 152 C 82 150 90 154 94 164 C 98 182 98 212 94 248 '
        'C 90 278 82 298 74 304 C 68 300 64 278 62 242 C 60 206 '
        '62 172 66 158 C 68 154 74 152 74 152 Z',
  ),
  MusclePathDef(
    id: 'quads',
    label: '',
    labelAnchor: const Offset(0.7, 0.58),
    labelOnLeft: false,
    pathData:
        'M 126 152 C 118 150 110 154 106 164 C 102 182 102 212 106 248 '
        'C 110 278 118 298 126 304 C 132 300 136 278 138 242 C 140 206 '
        '138 172 134 158 C 132 154 126 152 126 152 Z',
  ),
  MusclePathDef(
    id: 'adductors',
    label: 'Aductores',
    labelAnchor: const Offset(0.5, 0.52),
    pathData:
        'M 90 152 C 96 156 100 164 104 158 C 108 164 110 178 108 194 '
        'C 106 208 100 218 96 214 C 92 202 90 188 88 172 C 88 164 88 158 90 152 Z',
  ),
  MusclePathDef(
    id: 'calves',
    label: 'Gemelos',
    labelAnchor: const Offset(0.28, 0.78),
    pathData:
        'M 68 304 C 72 312 74 328 72 352 C 70 374 64 392 58 400 '
        'C 52 404 48 396 48 374 C 48 350 52 326 58 308 C 62 300 64 302 68 304 Z',
  ),
  MusclePathDef(
    id: 'calves',
    label: '',
    labelAnchor: const Offset(0.72, 0.78),
    labelOnLeft: false,
    pathData:
        'M 132 304 C 128 312 126 328 128 352 C 130 374 136 392 142 400 '
        'C 148 404 152 396 152 374 C 152 350 148 326 142 308 C 138 300 '
        '136 302 132 304 Z',
  ),
];

final backMusclePaths = <MusclePathDef>[
  MusclePathDef(
    id: 'traps',
    label: 'Trapecio',
    labelAnchor: const Offset(0.5, 0.16),
    labelOnLeft: false,
    pathData:
        'M 100 42 L 128 52 C 138 58 142 66 140 74 C 136 82 124 86 100 88 '
        'C 76 86 64 82 60 74 C 58 66 62 58 72 52 L 100 42 Z',
  ),
  MusclePathDef(
    id: 'back',
    label: 'Dorsales',
    labelAnchor: const Offset(0.5, 0.32),
    labelOnLeft: false,
    pathData:
        'M 64 78 C 54 86 48 100 46 118 C 44 136 50 152 62 164 C 72 172 '
        '82 176 92 174 C 88 168 86 158 88 146 C 90 128 96 112 104 100 '
        'C 98 92 90 86 82 82 C 74 78 68 76 64 78 Z',
  ),
  MusclePathDef(
    id: 'back',
    label: '',
    labelAnchor: const Offset(0.5, 0.32),
    labelOnLeft: false,
    pathData:
        'M 136 78 C 146 86 152 100 154 118 C 156 136 150 152 138 164 '
        'C 128 172 118 176 108 174 C 112 168 114 158 112 146 C 110 128 '
        '104 112 96 100 C 102 92 110 86 118 82 C 126 78 132 76 136 78 Z',
  ),
  MusclePathDef(
    id: 'triceps',
    label: 'Tríceps',
    labelAnchor: const Offset(0.12, 0.3),
    pathData:
        'M 50 68 C 42 74 36 88 34 108 C 32 128 36 146 44 156 C 52 162 '
        '60 156 66 138 C 68 118 64 98 56 82 C 52 72 50 68 50 68 Z',
  ),
  MusclePathDef(
    id: 'triceps',
    label: '',
    labelAnchor: const Offset(0.88, 0.3),
    labelOnLeft: false,
    pathData:
        'M 150 68 C 158 74 164 88 166 108 C 168 128 164 146 156 156 '
        'C 148 162 140 156 134 138 C 132 118 136 98 144 82 C 148 72 '
        '150 68 150 68 Z',
  ),
  MusclePathDef(
    id: 'glutes',
    label: 'Glúteos',
    labelAnchor: const Offset(0.35, 0.48),
    pathData:
        'M 72 158 C 80 154 90 152 98 154 C 100 158 100 166 96 174 '
        'C 90 182 82 186 76 184 C 70 180 68 172 70 164 L 72 158 Z',
  ),
  MusclePathDef(
    id: 'glutes',
    label: '',
    labelAnchor: const Offset(0.65, 0.48),
    labelOnLeft: false,
    pathData:
        'M 128 158 C 120 154 110 152 102 154 C 100 158 100 166 104 174 '
        'C 110 182 118 186 124 184 C 130 180 132 172 130 164 L 128 158 Z',
  ),
  MusclePathDef(
    id: 'hamstrings',
    label: 'Isquiotibiales',
    labelAnchor: const Offset(0.28, 0.62),
    pathData:
        'M 68 188 C 76 186 84 192 88 206 C 92 228 90 258 84 284 '
        'C 78 302 70 308 62 302 C 56 290 54 264 56 234 C 58 206 '
        '62 188 68 188 Z',
  ),
  MusclePathDef(
    id: 'hamstrings',
    label: '',
    labelAnchor: const Offset(0.72, 0.62),
    labelOnLeft: false,
    pathData:
        'M 132 188 C 124 186 116 192 112 206 C 108 228 110 258 116 284 '
        'C 122 302 130 308 138 302 C 144 290 146 264 144 234 C 142 206 '
        '138 188 132 188 Z',
  ),
  MusclePathDef(
    id: 'calves',
    label: 'Gemelos',
    labelAnchor: const Offset(0.28, 0.8),
    pathData:
        'M 66 308 C 70 318 72 338 70 364 C 68 386 62 404 54 412 '
        'C 46 416 40 406 40 382 C 40 356 44 330 52 312 C 58 302 62 304 66 308 Z',
  ),
  MusclePathDef(
    id: 'calves',
    label: '',
    labelAnchor: const Offset(0.72, 0.8),
    labelOnLeft: false,
    pathData:
        'M 134 308 C 130 318 128 338 130 364 C 132 386 138 404 146 412 '
        'C 154 416 160 406 160 382 C 160 356 156 330 148 312 C 142 302 '
        '138 304 134 308 Z',
  ),
];

Path bodyOutlinePath(Rect rect, {required bool isFront}) =>
    bodySilhouettePath(rect, isFront: isFront);
