import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Espacio de diseño (proporción ~1:2.4, estilo mapa anatómico).
const bodySilhouetteDesignSize = Size(200, 480);

/// Vista frontal — contorno continuo, brazos ligeramente abiertos.
const frontSilhouettePath =
    'M 100 6 '
    'C 118 6 131 18 133 34 '
    'C 134 46 128 56 118 62 '
    'C 112 66 106 68 102 70 '
    'C 128 74 150 88 158 106 '
    'C 165 124 167 146 165 168 '
    'C 162 190 157 212 151 234 '
    'C 146 256 144 278 146 298 '
    'C 148 314 153 326 160 332 '
    'C 166 336 169 332 170 322 '
    'C 171 304 167 282 161 260 '
    'C 153 228 142 198 128 172 '
    'C 120 156 114 144 110 134 '
    'C 114 152 116 172 116 192 '
    'C 116 212 114 232 110 252 '
    'C 108 272 110 294 116 316 '
    'C 120 338 118 364 110 388 '
    'C 106 406 104 424 106 440 '
    'C 108 452 114 458 122 460 '
    'L 100 464 '
    'L 78 460 '
    'C 86 458 92 452 94 440 '
    'C 96 424 94 406 90 388 '
    'C 82 364 80 338 84 316 '
    'C 90 294 92 272 90 252 '
    'C 86 232 84 212 84 192 '
    'C 84 172 86 152 90 134 '
    'C 86 144 80 156 72 172 '
    'C 58 198 47 228 39 260 '
    'C 33 282 29 304 30 322 '
    'C 31 332 34 336 40 332 '
    'C 47 326 52 314 54 298 '
    'C 56 278 54 256 49 234 '
    'C 43 212 38 190 35 168 '
    'C 33 146 35 124 42 106 '
    'C 50 88 72 74 98 70 '
    'C 94 68 88 66 82 62 '
    'C 72 56 66 46 67 34 '
    'C 69 18 82 6 100 6 Z';

/// Vista posterior — hombros más anchos, espalda en V y glúteos redondeados.
const backSilhouettePath =
    'M 100 6 '
    'C 118 6 131 18 133 34 '
    'C 134 46 128 56 118 62 '
    'C 112 66 106 68 102 70 '
    'C 132 74 158 92 168 114 '
    'C 175 138 176 164 173 190 '
    'C 169 216 162 242 154 268 '
    'C 147 294 144 320 145 344 '
    'C 147 362 152 376 160 384 '
    'C 167 390 171 386 172 374 '
    'C 173 354 168 330 160 304 '
    'C 150 272 136 242 120 218 '
    'C 112 202 108 190 106 182 '
    'C 110 202 112 224 112 246 '
    'C 112 268 110 290 106 312 '
    'C 104 334 106 358 112 382 '
    'C 116 402 114 424 108 442 '
    'C 104 456 96 464 86 468 '
    'L 100 472 '
    'L 114 468 '
    'C 104 464 96 456 92 442 '
    'C 86 424 84 402 88 382 '
    'C 94 358 96 334 94 312 '
    'C 90 290 88 268 88 246 '
    'C 88 224 90 202 94 182 '
    'C 92 190 88 202 80 218 '
    'C 64 242 50 272 40 304 '
    'C 32 330 27 354 28 374 '
    'C 29 386 33 390 40 384 '
    'C 48 376 53 362 55 344 '
    'C 56 320 53 294 46 268 '
    'C 38 242 31 216 27 190 '
    'C 24 164 25 138 32 114 '
    'C 42 92 68 74 98 70 '
    'C 94 68 88 66 82 62 '
    'C 72 56 66 46 67 34 '
    'C 69 18 82 6 100 6 Z';

Path bodySilhouettePath(Rect rect, {required bool isFront}) {
  final parsed = parseSvgPathData(
    isFront ? frontSilhouettePath : backSilhouettePath,
  );
  final scaleX = rect.width / bodySilhouetteDesignSize.width;
  final scaleY = rect.height / bodySilhouetteDesignSize.height;
  final matrix = Matrix4.identity()
    ..translateByDouble(rect.left, rect.top, 0, 1)
    ..scaleByDouble(scaleX, scaleY, 1, 1);
  return parsed.transform(matrix.storage);
}
