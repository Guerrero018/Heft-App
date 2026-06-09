import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/routines/domain/routine_progress.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';

void main() {
  test('buildRoutineProgress aggregates sessions and exercise bests', () {
    final sessions = [
      WorkoutSession(
        id: 1,
        routineId: 10,
        name: 'Push',
        date: DateTime(2026, 6, 1),
        startTime: DateTime(2026, 6, 1, 10, 0),
        endTime: DateTime(2026, 6, 1, 11, 0),
        isCompleted: true,
        sets: [
          WorkoutSet(
            exerciseId: 101,
            exerciseName: 'Press',
            setNumber: 1,
            setType: 'normal',
            weight: 60,
            reps: 10,
            isCompleted: true,
          ),
        ],
      ),
      WorkoutSession(
        id: 2,
        routineId: 10,
        name: 'Push',
        date: DateTime(2026, 6, 8),
        startTime: DateTime(2026, 6, 8, 10, 0),
        endTime: DateTime(2026, 6, 8, 10, 45),
        isCompleted: true,
        sets: [
          WorkoutSet(
            exerciseId: 101,
            exerciseName: 'Press',
            setNumber: 1,
            setType: 'normal',
            weight: 65,
            reps: 8,
            isCompleted: true,
          ),
        ],
      ),
    ];

    final progress = buildRoutineProgress(sessions: sessions);

    expect(progress.totalSessions, 2);
    expect(progress.totalVolumeKg, 60 * 10 + 65 * 8);
    expect(progress.exerciseProgress.length, 1);
    expect(progress.exerciseProgress.first.bestWeight, 65);
    expect(progress.exerciseProgress.first.lastWeight, 65);
    expect(progress.recentSessions.length, 2);
  });

  test('buildRoutineProgress returns empty stats without sessions', () {
    final progress = buildRoutineProgress(sessions: []);
    expect(progress.totalSessions, 0);
    expect(progress.exerciseProgress, isEmpty);
  });

  test('buildRoutineProgress only includes exercises from the routine', () {
    final sessions = [
      WorkoutSession(
        id: 1,
        routineId: 10,
        name: 'Push',
        date: DateTime(2026, 6, 8),
        startTime: DateTime(2026, 6, 8, 10, 0),
        endTime: DateTime(2026, 6, 8, 10, 45),
        isCompleted: true,
        sets: [
          WorkoutSet(
            exerciseId: 101,
            exerciseName: 'Press',
            setNumber: 1,
            setType: 'normal',
            weight: 60,
            reps: 10,
            isCompleted: true,
          ),
          WorkoutSet(
            exerciseId: 999,
            exerciseName: 'Peso muerto',
            setNumber: 2,
            setType: 'normal',
            weight: 120,
            reps: 5,
            isCompleted: true,
          ),
        ],
      ),
    ];

    final progress = buildRoutineProgress(
      sessions: sessions,
      routineExerciseIds: {101},
    );

    expect(progress.exerciseProgress.length, 1);
    expect(progress.exerciseProgress.first.exerciseId, 101);
    expect(progress.totalVolumeKg, 600);
  });
}
