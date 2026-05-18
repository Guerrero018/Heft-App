import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/statistics/data/statistics_provider.dart';
import 'package:frontend/features/statistics/domain/statistics_model.dart';
import 'package:frontend/features/statistics/presentation/statistics_screen.dart';

UserStatistics _emptyStats() {
  return UserStatistics(
    period: 'week',
    periodLabel: 'Semana',
    periodEnd: '2026-05-18',
    summary: StatisticsSummary(
      totalWorkouts: 0,
      totalVolumeKg: 0,
      totalSets: 0,
      workoutDays: 0,
      expectedWorkoutDays: 3,
      adherencePercent: 0,
      streakDays: 0,
    ),
    dailyVolume: [],
    volumeByMuscleGroup: [],
    muscleMap: MuscleMapData(front: {}, back: {}),
    exerciseProgress: [],
  );
}

void main() {
  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        statisticsProvider.overrideWith(() => _FakeStatisticsNotifier()),
      ],
      child: const MaterialApp(
        home: StatisticsScreen(),
      ),
    );
  }

  testWidgets('StatisticsScreen shows title and tabs', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Gráficos'), findsOneWidget);
    expect(find.text('Mapa Muscular'), findsOneWidget);
  });

  testWidgets('Switching tabs changes content', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Entrenos'), findsOneWidget);
    expect(find.text('Fatiga muscular'), findsNothing);

    await tester.tap(find.text('Mapa Muscular'));
    await tester.pumpAndSettle();

    expect(find.text('Fatiga muscular'), findsOneWidget);
    expect(find.text('Entrenos'), findsNothing);
  });

  testWidgets('Period selector is visible', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Semana'), findsOneWidget);
    expect(find.text('Mes'), findsOneWidget);
  });
}

class _FakeStatisticsNotifier extends StatisticsNotifier {
  @override
  StatisticsState build() {
    final week = _emptyStats();
    return StatisticsState(data: week, muscleMapWeekData: week);
  }

  @override
  Future<void> fetchStatistics(String uiPeriod, {bool forceReload = false}) async {}

  @override
  Future<void> fetchMuscleMapWeek({bool forceReload = false}) async {}
}
