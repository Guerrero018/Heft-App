import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/label_translations.dart';
import '../../exercises/data/exercise_provider.dart';
import '../../exercises/domain/exercise_model.dart';
import '../../exercises/presentation/exercise_picker_bottom_sheet.dart';
import '../data/statistics_charts_preferences_provider.dart';
import '../data/statistics_provider.dart';
import '../domain/statistics_model.dart';
import 'widgets/interactive_muscle_map.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartScrubActive = ref.watch(chartScrubActiveProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 90,
          title: const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor,
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.hintColor,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Gráficos'),
                  Tab(text: 'Mapa Muscular'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          physics: chartScrubActive
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics(),
          children: const [
            _ChartsTab(),
            _MuscleMapTab(),
          ],
        ),
      ),
    );
  }
}

class _ChartsTab extends ConsumerStatefulWidget {
  const _ChartsTab();

  @override
  ConsumerState<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends ConsumerState<_ChartsTab> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statisticsProvider);

    if (state.isLoading && state.data == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (state.error != null && state.data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ErrorBanner(message: state.error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(statisticsProvider.notifier)
                    .fetchStatistics(
                      state.selectedPeriod,
                      forceReload: true,
                    ),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = state.data;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => ref
          .read(statisticsProvider.notifier)
          .fetchStatistics(state.selectedPeriod, forceReload: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.cardColor,
                ),
              ),
            _PeriodSelector(
              selectedPeriod: state.selectedPeriod,
              onPeriodSelected: (period) => ref
                  .read(statisticsProvider.notifier)
                  .fetchStatistics(period),
            ),
            const SizedBox(height: 24),
            if (stats != null) ...[
              _SummaryGrid(summary: stats.summary),
              const SizedBox(height: 24),
              if (!stats.hasData) ...[
                _buildEmptyState(stats.periodLabel),
                const SizedBox(height: 24),
              ],
              _ExerciseChartsSection(
                exercises: stats.exerciseProgress,
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String periodLabel) {
    return _buildHintCard(
      'No hay entrenamientos en $periodLabel. '
      'Prueba con «Mes», «Año» o «Todo», o finaliza una sesión desde Inicio.',
    );
  }

  Widget _buildHintCard(String message) => _StatisticsHintCard(message: message);
}

class _PeriodSelector extends StatelessWidget {
  static const periods = ['Semana', 'Mes', '3 Meses', 'Año', 'Todo'];

  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;

  const _PeriodSelector({
    required this.selectedPeriod,
    required this.onPeriodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: periods.map((period) {
          final isSelected = selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(period),
              selected: isSelected,
              onSelected: (_) => onPeriodSelected(period),
              backgroundColor: AppTheme.cardColor,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.black : AppTheme.hintColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide.none,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExerciseChartsSection extends ConsumerWidget {
  final List<ExerciseProgress> exercises;

  const _ExerciseChartsSection({required this.exercises});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinned = ref.watch(pinnedExerciseChartsProvider);
    final progressById = {for (final e in exercises) e.exerciseId: e};
    final catalogById = {
      for (final e in ref.watch(exerciseProvider).exercises) e.id: e,
    };

    final pinnedCharts = <ExerciseProgress>[];
    for (final pinnedRef in pinned) {
      final id = pinnedRef.exerciseId;
      if (progressById.containsKey(id)) {
        pinnedCharts.add(progressById[id]!);
        continue;
      }

      final catalog = catalogById[id];
      final name = pinnedRef.exerciseName.isNotEmpty
          ? pinnedRef.exerciseName
          : (catalog?.name ?? 'Ejercicio');
      final muscle = pinnedRef.muscleGroup.isNotEmpty
          ? pinnedRef.muscleGroup
          : (catalog?.muscleGroup ?? '');

      pinnedCharts.add(
        ExerciseProgress(
          exerciseId: id,
          exerciseName: name,
          muscleGroup: muscle,
          muscleGroupLabel: muscle,
          volumeTrendPercent: 0,
          maxWeightTrendPercent: 0,
          dataPoints: const [],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Progreso por ejercicio',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddExerciseSheet(context, ref),
              icon: const Icon(Icons.add_chart_outlined, size: 20),
              label: const Text('Añadir gráfico'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (pinnedCharts.isEmpty)
          _StatisticsHintCard(
            message:
                'Pulsa «Añadir gráfico» para fijar ejercicios. Se guardan hasta que los quites con ✕.',
          )
        else
          ...pinnedCharts.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ExerciseProgressChart(
                exercise: ex,
                onRemove: () => ref
                    .read(pinnedExerciseChartsProvider.notifier)
                    .unpin(ex.exerciseId),
              ),
            ),
          ),
      ],
    );
  }

  void _showAddExerciseSheet(BuildContext context, WidgetRef ref) {
    final pinnedIds =
        ref.read(pinnedExerciseChartsProvider.notifier).pinnedIds;

    showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ExercisePickerBottomSheet(
        title: 'Añadir gráfico',
        excludeExerciseIds: pinnedIds,
      ),
    ).then((selected) async {
      if (selected != null) {
        await ref
            .read(pinnedExerciseChartsProvider.notifier)
            .pin(selected);
      }
    });
  }
}

class _StatisticsHintCard extends StatelessWidget {
  final String message;

  const _StatisticsHintCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: AppTheme.hintColor, height: 1.4),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF7A7A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.14), AppTheme.cardColor),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final StatisticsSummary summary;

  const _SummaryGrid({required this.summary});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'Entrenos',
              value: '${summary.totalWorkouts}',
              icon: Icons.fitness_center,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'Volumen',
              value: _formatVolume(summary.totalVolumeKg),
              valueSuffix: ' kg',
              icon: Icons.analytics_outlined,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SummaryCard(
              label: 'Adherencia',
              value: '${summary.adherencePercent}',
              valueSuffix: '%',
              icon: Icons.calendar_today_outlined,
              footnote:
                  '${summary.workoutDays}/${summary.expectedWorkoutDays}',
            ),
          ),
        ],
      ),
    );
  }

  String _formatVolume(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String valueSuffix;
  final String? footnote;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    this.valueSuffix = '',
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                ),
                if (valueSuffix.isNotEmpty)
                  TextSpan(
                    text: valueSuffix,
                    style: TextStyle(
                      color: AppTheme.hintColor.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.hintColor, fontSize: 10),
          ),
          if (footnote != null) ...[
            const SizedBox(height: 2),
            Text(
              footnote!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.hintColor.withValues(alpha: 0.55),
                fontSize: 9,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MuscleGroupChip extends StatelessWidget {
  final String muscleGroup;

  const _MuscleGroupChip({required this.muscleGroup});

  @override
  Widget build(BuildContext context) {
    if (muscleGroup.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        translateMuscleGroup(muscleGroup).toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ExerciseProgressChart extends StatelessWidget {
  final ExerciseProgress exercise;
  final VoidCallback? onRemove;

  const _ExerciseProgressChart({
    required this.exercise,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: Icon(
                    Icons.close,
                    size: 20,
                    color: AppTheme.hintColor.withValues(alpha: 0.8),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  tooltip: 'Quitar gráfico',
                ),
            ],
          ),
          const SizedBox(height: 8),
          _MuscleGroupChip(muscleGroup: exercise.muscleGroup),
          const SizedBox(height: 20),
          _ExerciseMetricLineChart(
            label: 'Volumen por sesión',
            trendPercent: exercise.volumeTrendPercent,
            values: exercise.dataPoints.map((p) => p.volume).toList(),
            dates: exercise.dataPoints.map((p) => p.date).toList(),
            lineColor: AppTheme.primaryColor,
            fillColor: AppTheme.primaryColor.withValues(alpha: 0.14),
          ),
          const SizedBox(height: 20),
          _ExerciseMetricLineChart(
            label: 'Peso máximo',
            trendPercent: exercise.maxWeightTrendPercent,
            values: exercise.dataPoints.map((p) => p.maxWeight).toList(),
            dates: exercise.dataPoints.map((p) => p.date).toList(),
            lineColor: const Color(0xFFB5C04A),
            fillColor: const Color(0xFFB5C04A).withValues(alpha: 0.1),
          ),
        ],
      ),
    );
  }
}

class _ExerciseMetricLineChart extends ConsumerStatefulWidget {
  static const Color _chartLabelColor = Color(0xFF6A6A6A);

  final String label;
  final double trendPercent;
  final List<double> values;
  final List<String> dates;
  final Color lineColor;
  final Color fillColor;

  const _ExerciseMetricLineChart({
    required this.label,
    required this.trendPercent,
    required this.values,
    required this.dates,
    required this.lineColor,
    required this.fillColor,
  });

  @override
  ConsumerState<_ExerciseMetricLineChart> createState() =>
      _ExerciseMetricLineChartState();
}

class _ExerciseMetricLineChartState
    extends ConsumerState<_ExerciseMetricLineChart> {
  static const double _chartLeftPadding = 36;
  static const double _chartRightPadding = 4;

  int? _scrubIndex;
  double? _touchedKg;
  ScrollHoldController? _scrollHold;

  static double _chartMaxY(List<double> values) {
    if (values.isEmpty) return 1;
    final max = values.reduce((a, b) => a > b ? a : b);
    if (max <= 0) return 1;
    return max * 1.12;
  }

  static double _yInterval(double maxY) {
    if (maxY <= 0) return 1;
    final rough = maxY / 3;
    if (rough >= 1000) {
      final step = (rough / 500).ceil() * 500.0;
      return step > 0 ? step : 500;
    }
    if (rough >= 100) return (rough / 50).ceil() * 50.0;
    if (rough >= 10) return (rough / 5).ceil() * 5.0;
    if (rough >= 1) return (rough).ceilToDouble().clamp(1, double.infinity);
    return (rough * 10).ceil() / 10;
  }

  static String _formatYLabel(double value) {
    if (value >= 10000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    if (value >= 100) return value.round().toString();
    if ((value - value.round()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static String _formatTooltipKg(double value) {
    if (value >= 1000) {
      final rounded = value.round();
      return rounded.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]}.',
          );
    }
    if ((value - value.round()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  static String _formatSessionDate(String iso) {
    final parts = iso.split('-');
    if (parts.length == 3) return '${parts[2]}/${parts[1]}';
    return iso;
  }

  int _indexFromLocalDx(double dx, double chartWidth, int spotCount) {
    if (spotCount <= 1) return 0;
    final plotWidth = chartWidth - _chartLeftPadding - _chartRightPadding;
    if (plotWidth <= 0) return 0;
    final t = ((dx - _chartLeftPadding) / plotWidth).clamp(0.0, 1.0);
    return (t * (spotCount - 1)).round().clamp(0, spotCount - 1);
  }

  void _applyScrub(int index) {
    if (index < 0 || index >= widget.values.length) return;
    final kg = widget.values[index];
    if (_scrubIndex == index && _touchedKg == kg) return;
    setState(() {
      _scrubIndex = index;
      _touchedKg = kg;
    });
  }

  void _onPointerDown(PointerDownEvent event, double chartWidth) {
    if (widget.values.length < 2) return;
    ref.read(chartScrubActiveProvider.notifier).setActive(true);
    _scrollHold?.cancel();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _scrollHold = scrollable.position.hold(() {});
    }
    _applyScrub(_indexFromLocalDx(event.localPosition.dx, chartWidth, widget.values.length));
  }

  void _onPointerMove(PointerMoveEvent event, double chartWidth) {
    if (widget.values.length < 2) return;
    _applyScrub(_indexFromLocalDx(event.localPosition.dx, chartWidth, widget.values.length));
  }

  void _endScrub() {
    ref.read(chartScrubActiveProvider.notifier).setActive(false);
    _scrollHold?.cancel();
    _scrollHold = null;
    if (_scrubIndex == null && _touchedKg == null) return;
    setState(() {
      _scrubIndex = null;
      _touchedKg = null;
    });
  }

  @override
  void dispose() {
    ref.read(chartScrubActiveProvider.notifier).setActive(false);
    _scrollHold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final dates = widget.dates;
    final spots = values
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final chartMaxY = _chartMaxY(values);
    final yInterval = _yInterval(chartMaxY);

    final trendColor =
        widget.trendPercent >= 0 ? Colors.greenAccent : const Color(0xFFFF7A7A);
    final trendPrefix = widget.trendPercent > 0 ? '+' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.label} (kg)',
                style: const TextStyle(
                  color: AppTheme.hintColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (_touchedKg != null)
              Text(
                '${_formatTooltipKg(_touchedKg!)} kg',
                style: TextStyle(
                  color: widget.lineColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              )
            else if (spots.length >= 2)
              Text(
                '$trendPrefix${widget.trendPercent.toStringAsFixed(1)}%',
                style: TextStyle(color: trendColor, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: values.isEmpty
              ? Center(
                  child: Text(
                    'Sin datos en este periodo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppTheme.hintColor.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                )
              : spots.length < 2
                  ? Center(
                      child: Text(
                        'Necesitas al menos 2 sesiones para ver la tendencia',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.hintColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final chartWidth = constraints.maxWidth;
                        final scrubIndex = _scrubIndex;
                        final barData = LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: widget.lineColor,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          showingIndicators: scrubIndex != null
                              ? [scrubIndex]
                              : const [],
                          belowBarData: BarAreaData(
                            show: true,
                            color: widget.fillColor,
                          ),
                        );

                        return Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerDown: (e) => _onPointerDown(e, chartWidth),
                          onPointerMove: (e) => _onPointerMove(e, chartWidth),
                          onPointerUp: (_) => _endScrub(),
                          onPointerCancel: (_) => _endScrub(),
                          child: LineChart(
                            LineChartData(
                              minY: 0,
                              maxY: chartMaxY,
                              showingTooltipIndicators: scrubIndex != null
                                  ? [
                                      ShowingTooltipIndicators([
                                        LineBarSpot(
                                          barData,
                                          0,
                                          spots[scrubIndex],
                                        ),
                                      ]),
                                    ]
                                  : const [],
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: yInterval,
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: Colors.white.withValues(alpha: 0.04),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: _chartLeftPadding,
                                    interval: yInterval,
                                    getTitlesWidget: (value, meta) {
                                      if (value < 0 ||
                                          value > chartMaxY + 0.01) {
                                        return const SizedBox.shrink();
                                      }
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Text(
                                          _formatYLabel(value),
                                          style: const TextStyle(
                                            color: _ExerciseMetricLineChart
                                                ._chartLabelColor,
                                            fontSize: 9,
                                            height: 1,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                bottomTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              lineTouchData: LineTouchData(
                                enabled: true,
                                handleBuiltInTouches: false,
                                getTouchedSpotIndicator:
                                    (barData, spotIndexes) {
                                  return spotIndexes.map((index) {
                                    return TouchedSpotIndicatorData(
                                      FlLine(
                                        color: widget.lineColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        strokeWidth: 1.5,
                                        dashArray: [5, 4],
                                      ),
                                      FlDotData(
                                        show: true,
                                        getDotPainter: (
                                          spot,
                                          percent,
                                          bar,
                                          i,
                                        ) =>
                                            FlDotCirclePainter(
                                          radius: 5,
                                          color: widget.lineColor,
                                          strokeWidth: 2,
                                          strokeColor: AppTheme.surfaceColor,
                                        ),
                                      ),
                                    );
                                  }).toList();
                                },
                                touchTooltipData: LineTouchTooltipData(
                                  tooltipBorderRadius: BorderRadius.circular(8),
                                  tooltipPadding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  getTooltipColor: (_) =>
                                      const Color(0xFF252525),
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final idx = spot.spotIndex;
                                      final date =
                                          idx >= 0 && idx < dates.length
                                              ? _formatSessionDate(dates[idx])
                                              : '';
                                      return LineTooltipItem(
                                        '${_formatTooltipKg(spot.y)} kg',
                                        TextStyle(
                                          color: widget.lineColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        children: [
                                          if (date.isNotEmpty)
                                            TextSpan(
                                              text: '\n$date',
                                              style: TextStyle(
                                                color: AppTheme.hintColor
                                                    .withValues(alpha: 0.9),
                                                fontSize: 10,
                                                fontWeight: FontWeight.normal,
                                              ),
                                            ),
                                        ],
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              lineBarsData: [barData],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _MuscleVolumeBarChart extends StatelessWidget {
  final List<MuscleVolumeItem> items;

  const _MuscleVolumeBarChart({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyChartPlaceholder(
        message: 'Sin volumen por grupo muscular en este periodo.',
      );
    }

    final maxVol = items.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    final maxY = maxVol * 1.15;

    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final label = items[i].label;
                  final short = label.length > 6
                      ? '${label.substring(0, 5)}.'
                      : label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      short,
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            items.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: items[i].volume,
                  color: AppTheme.primaryColor,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyVolumeChart extends StatelessWidget {
  final List<DailyVolumePoint> points;

  const _DailyVolumeChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxVol = points.map((e) => e.volume).reduce((a, b) => a > b ? a : b);
    final maxY = maxVol * 1.15;

    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      points[i].label,
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(
            points.length,
            (i) => BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].volume,
                  color: AppTheme.primaryColor.withValues(alpha: 0.85),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  final String message;

  const _EmptyChartPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
      ),
    );
  }
}

class _MuscleMapTab extends ConsumerWidget {
  const _MuscleMapTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(statisticsProvider);
    final weekStats = state.muscleMapWeekData;

    if (state.muscleMapLoading && weekStats == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (state.muscleMapError != null && weekStats == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ErrorBanner(message: state.muscleMapError!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(statisticsProvider.notifier)
                    .fetchMuscleMapWeek(forceReload: true),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final stats = weekStats;
    final frontLoads = stats?.muscleMap.front ?? {};
    final backLoads = stats?.muscleMap.back ?? {};
    final hasWeekVolume = stats?.hasData ?? false;

    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () => ref
          .read(statisticsProvider.notifier)
          .fetchMuscleMapWeek(forceReload: true),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.muscleMapLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(
                  color: AppTheme.primaryColor,
                  backgroundColor: AppTheme.cardColor,
                ),
              ),
            const Text(
              'Fatiga muscular',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Carga acumulada en los últimos 7 días',
              style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            InteractiveMuscleMap(
              frontLoads: frontLoads,
              backLoads: backLoads,
            ),
            if (!hasWeekVolume) ...[
              const SizedBox(height: 16),
              const _StatisticsHintCard(
                message:
                    'No has registrado volumen en la última semana. El mapa se coloreará cuando entrenes.',
              ),
            ],
            const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MuscleMapLegendItem(
                      label: 'Sin carga',
                      color: Color(0xFFBDBDBD),
                    ),
                    _MuscleMapLegendItem(
                      label: 'Baja',
                      color: Color(0xFFF2E8B8),
                    ),
                    _MuscleMapLegendItem(
                      label: 'Media',
                      color: Color(0xFFE6D14D),
                    ),
                    _MuscleMapLegendItem(
                      label: 'Alta',
                      color: Color(0xFFD4A017),
                    ),
                  ],
                ),
              ),
            if (stats != null && stats.volumeByMuscleGroup.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Volumen por grupo muscular (semana)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _MuscleVolumeBarChart(items: stats.volumeByMuscleGroup),
            ],
            if (stats != null && stats.dailyVolume.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Volumen diario (semana)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 16),
              _DailyVolumeChart(points: stats.dailyVolume),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _MuscleMapLegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _MuscleMapLegendItem({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
        ),
      ],
    );
  }
}
