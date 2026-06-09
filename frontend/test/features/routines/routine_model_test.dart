import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/routines/domain/routine_model.dart';

void main() {
  test('Routine.fromJson parses nested exercises', () {
    final routine = Routine.fromJson({
      'id': 1,
      'name': 'Push',
      'description': 'Pecho',
      'is_active': true,
      'exercises': [
        {
          'id': 10,
          'exercise': 101,
          'exercise_name': 'Press',
          'muscle_group': 'pecho',
          'order': 1,
          'target_sets': 3,
          'target_reps': 10,
          'target_weight': 60.0,
          'rest_time_seconds': 90,
        },
      ],
    });

    expect(routine.name, 'Push');
    expect(routine.isActive, true);
    expect(routine.exercises, hasLength(1));
    expect(routine.exercises.first.exerciseName, 'Press');
    expect(routine.exercises.first.targetSets, 3);
  });
}
