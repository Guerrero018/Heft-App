import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/workouts/domain/workout_model.dart';
import 'package:frontend/features/workouts/presentation/screens/workout_detail_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es', null);
  });

  testWidgets('WorkoutDetailScreen should display correct total volume', (WidgetTester tester) async {
    // Create a workout with a known total volume
    final workout = WorkoutSession(
      name: 'Entrenamiento de Prueba',
      date: DateTime(2026, 5, 5),
      startTime: DateTime(2026, 5, 5, 10, 0),
      endTime: DateTime(2026, 5, 5, 11, 0),
      sets: [
        WorkoutSet(
          exerciseId: 1,
          exerciseName: 'Press de Banca',
          setNumber: 1,
          setType: 'normal',
          weight: 60.0,
          reps: 10,
        ),
        WorkoutSet(
          exerciseId: 1,
          exerciseName: 'Press de Banca',
          setNumber: 2,
          setType: 'normal',
          weight: 70.0,
          reps: 8,
        ),
        WorkoutSet(
          exerciseId: 2,
          exerciseName: 'Sentadilla',
          setNumber: 1,
          setType: 'normal',
          weight: 100.0,
          reps: 5,
        ),
      ],
    );

    // Calculation:
    // (60 * 10) + (70 * 8) + (100 * 5)
    // 600 + 560 + 500 = 1660

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailScreen(workout: workout),
      ),
    );

    // Check if the calculated volume is displayed
    expect(find.text('1660 kg'), findsOneWidget);
    
    // Check if the label is present
    expect(find.text('VOLUMEN'), findsOneWidget);
  });

  testWidgets('WorkoutDetailScreen should display 0 kg when no sets are present', (WidgetTester tester) async {
    final workout = WorkoutSession(
      name: 'Entrenamiento Vacío',
      date: DateTime(2026, 5, 5),
      startTime: DateTime(2026, 5, 5, 10, 0),
      sets: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: WorkoutDetailScreen(workout: workout),
      ),
    );

    expect(find.text('0 kg'), findsOneWidget);
  });
}
