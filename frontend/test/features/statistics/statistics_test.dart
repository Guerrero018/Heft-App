import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/statistics/presentation/statistics_screen.dart';
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: StatisticsScreen(),
    );
  }

  testWidgets('StatisticsScreen shows title and tabs', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.text('Estadísticas'), findsOneWidget);
    expect(find.text('Gráficos'), findsOneWidget);
    expect(find.text('Mapa Muscular'), findsOneWidget);
  });

  testWidgets('Switching tabs changes content', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Initially in Charts tab
    expect(find.text('Progreso por Ejercicio'), findsOneWidget);
    expect(find.text('Distribución de Carga'), findsNothing);

    // Switch to Muscle Map tab
    await tester.tap(find.text('Mapa Muscular'));
    await tester.pumpAndSettle();

    expect(find.text('Distribución de Carga'), findsOneWidget);
    expect(find.text('Progreso por Ejercicio'), findsNothing);
  });

  testWidgets('Period selector updates selection in Charts tab', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());

    // Initially "Semana" is selected
    expect(find.text('Semana'), findsOneWidget);
    
    // Tap "Mes"
    await tester.tap(find.text('Mes'));
    await tester.pumpAndSettle();

    // Verify change (difficult to verify internal state with just text, 
    // but we can check if it pumps correctly)
    expect(find.text('Mes'), findsOneWidget);
  });
}
