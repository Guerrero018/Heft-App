import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';

void main() {
  group('WorkoutSession', () {
    test('totalVolume should return 0 when there are no sets', () {
      final session = WorkoutSession(
        name: 'Test Session',
        date: DateTime.now(),
        startTime: DateTime.now(),
        sets: [],
      );

      expect(session.totalVolume, 0);
    });

    test('totalVolume should calculate correctly for multiple sets', () {
      final session = WorkoutSession(
        name: 'Test Session',
        date: DateTime.now(),
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            setNumber: 1,
            setType: 'normal',
            weight: 60.0,
            reps: 10,
          ), // 600
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            setNumber: 2,
            setType: 'normal',
            weight: 60.0,
            reps: 8,
          ), // 480
          WorkoutSet(
            exerciseId: 2,
            exerciseName: 'Squat',
            setNumber: 1,
            setType: 'normal',
            weight: 100.0,
            reps: 5,
          ), // 500
        ],
      );

      // 600 + 480 + 500 = 1580
      expect(session.totalVolume, 1580.0);
    });

    test('uniqueExercisesCount should return the correct number of unique exercises', () {
      final session = WorkoutSession(
        name: 'Test Session',
        date: DateTime.now(),
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            setNumber: 1,
            setType: 'normal',
            weight: 60.0,
            reps: 10,
          ),
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Bench Press',
            setNumber: 2,
            setType: 'normal',
            weight: 60.0,
            reps: 8,
          ),
          WorkoutSet(
            exerciseId: 2,
            exerciseName: 'Squat',
            setNumber: 1,
            setType: 'normal',
            weight: 100.0,
            reps: 5,
          ),
        ],
      );

      expect(session.uniqueExercisesCount, 2);
    });

    test('totalVolume should handle zero weights or reps', () {
      final session = WorkoutSession(
        name: 'Test Session',
        date: DateTime.now(),
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(
            exerciseId: 1,
            exerciseName: 'Push Up',
            setNumber: 1,
            setType: 'normal',
            weight: 0.0,
            reps: 20,
          ),
          WorkoutSet(
            exerciseId: 2,
            exerciseName: 'Failed Rep',
            setNumber: 1,
            setType: 'normal',
            weight: 100.0,
            reps: 0,
          ),
        ],
      );

      expect(session.totalVolume, 0.0);
    });

    test('totalVolume should match user example (50x12, 50x10, 50x8 + 10x11)', () {
      final session = WorkoutSession(
        name: 'User Example',
        date: DateTime.now(),
        startTime: DateTime.now(),
        sets: [
          WorkoutSet(exerciseId: 1, exerciseName: 'E1', setNumber: 1, setType: 'normal', weight: 50, reps: 12),
          WorkoutSet(exerciseId: 1, exerciseName: 'E1', setNumber: 2, setType: 'normal', weight: 50, reps: 10),
          WorkoutSet(exerciseId: 1, exerciseName: 'E1', setNumber: 3, setType: 'normal', weight: 50, reps: 8),
          WorkoutSet(exerciseId: 2, exerciseName: 'E2', setNumber: 1, setType: 'normal', weight: 10, reps: 11),
        ],
      );

      // (50*12) + (50*10) + (50*8) + (10*11) = 600 + 500 + 400 + 110 = 1610
      expect(session.totalVolume, 1610.0);
    });
  });
}
