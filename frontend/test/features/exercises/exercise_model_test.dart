import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/exercises/domain/exercise_model.dart';

void main() {
  test('Exercise.fromJson maps fields', () {
    final exercise = Exercise.fromJson({
      'id': 7,
      'name': 'Press Banca',
      'muscle_group': 'pecho',
      'exercise_type': 'barra',
      'is_global': true,
      'gif_url': 'https://example.com/a.gif',
      'instructions': ['Paso 1'],
    });

    expect(exercise.id, 7);
    expect(exercise.name, 'Press Banca');
    expect(exercise.muscleGroup, 'pecho');
    expect(exercise.isGlobal, true);
    expect(exercise.gifUrl, 'https://example.com/a.gif');
    expect(exercise.instructions, ['Paso 1']);
  });
}
