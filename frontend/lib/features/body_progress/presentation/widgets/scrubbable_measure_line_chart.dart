import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/body_progress_chart_scrub_provider.dart';
import '../../domain/muscle_group_metrics.dart';

/// Gráfico de línea con scrub al arrastrar (como progreso por ejercicio).
class ScrubbableMeasureLineChart extends ConsumerStatefulWidget {
  final List<MeasureSeriesPoint> points;
  final Color lineColor;
  final String unitLabel;
  final double height;
  final String? headerLabel;

  const ScrubbableMeasureLineChart({
    super.key,
    required this.points,
    required this.lineColor,
    this.unitLabel = 'cm',
    this.height = 220,
    this.headerLabel,
  });

  @override
  ConsumerState<ScrubbableMeasureLineChart> createState() =>
      _ScrubbableMeasureLineChartState();
}

class _ScrubbableMeasureLineChartState
    extends ConsumerState<ScrubbableMeasureLineChart> {
  static const double _chartLeftPadding = 40;
  static const double _chartRightPadding = 8;

  int? _scrubIndex;
  double? _touchedValue;
  ScrollHoldController? _scrollHold;

  int _indexFromLocalDx(double dx, double chartWidth) {
    final n = widget.points.length;
    if (n <= 1) return 0;
    final plotWidth = chartWidth - _chartLeftPadding - _chartRightPadding;
    if (plotWidth <= 0) return 0;
    final t = ((dx - _chartLeftPadding) / plotWidth).clamp(0.0, 1.0);
    return (t * (n - 1)).round().clamp(0, n - 1);
  }

  void _applyScrub(int index) {
    if (index < 0 || index >= widget.points.length) return;
    final v = widget.points[index].valueCm;
    if (_scrubIndex == index && _touchedValue == v) return;
    setState(() {
      _scrubIndex = index;
      _touchedValue = v;
    });
  }

  void _onPointerDown(PointerDownEvent event, double chartWidth) {
    if (widget.points.length < 2) return;
    ref.read(bodyProgressChartScrubProvider.notifier).setActive(true);
    _scrollHold?.cancel();
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable != null) {
      _scrollHold = scrollable.position.hold(() {});
    }
    _applyScrub(_indexFromLocalDx(event.localPosition.dx, chartWidth));
  }

  void _onPointerMove(PointerMoveEvent event, double chartWidth) {
    if (widget.points.length < 2) return;
    _applyScrub(_indexFromLocalDx(event.localPosition.dx, chartWidth));
  }

  void _endScrub() {
    ref.read(bodyProgressChartScrubProvider.notifier).setActive(false);
    _scrollHold?.cancel();
    _scrollHold = null;
    if (_scrubIndex == null && _touchedValue == null) return;
    setState(() {
      _scrubIndex = null;
      _touchedValue = null;
    });
  }

  @override
  void dispose() {
    ref.read(bodyProgressChartScrubProvider.notifier).setActive(false);
    _scrollHold?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.length < 2) {
      return SizedBox(
        height: widget.height,
        child: const Center(
          child: Text(
            'Necesitas al menos 2 registros para ver la evolución',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.hintColor, fontSize: 13),
          ),
        ),
      );
    }

    final values = widget.points.map((p) => p.valueCm).toList();
    final minY = values.reduce((a, b) => a < b ? a : b) - 1;
    final maxY = values.reduce((a, b) => a > b ? a : b) + 1;
    final yInterval = ((maxY - minY) / 4).clamp(0.5, 20.0);

    final spots = widget.points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.valueCm))
        .toList();

    final scrubIndex = _scrubIndex;
    final barData = LineChartBarData(
      spots: spots,
      isCurved: true,
      color: widget.lineColor,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      showingIndicators: scrubIndex != null ? [scrubIndex] : const [],
      belowBarData: BarAreaData(
        show: true,
        color: widget.lineColor.withValues(alpha: 0.12),
      ),
    );

    final touchedPoint = scrubIndex != null ? widget.points[scrubIndex] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.headerLabel != null || touchedPoint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (widget.headerLabel != null)
                  Expanded(
                    child: Text(
                      widget.headerLabel!,
                      style: const TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (touchedPoint != null)
                  Text(
                    '${_touchedValue!.toStringAsFixed(1)} ${widget.unitLabel} · '
                    '${DateFormat('d MMM yyyy', 'es').format(touchedPoint.date)}',
                    style: TextStyle(
                      color: widget.lineColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
        SizedBox(
          height: widget.height,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth;
              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (e) => _onPointerDown(e, chartWidth),
                onPointerMove: (e) => _onPointerMove(e, chartWidth),
                onPointerUp: (_) => _endScrub(),
                onPointerCancel: (_) => _endScrub(),
                child: LineChart(
                  LineChartData(
                    minY: minY,
                    maxY: maxY,
                    showingTooltipIndicators: scrubIndex != null
                        ? [
                            ShowingTooltipIndicators([
                              LineBarSpot(barData, 0, spots[scrubIndex]),
                            ]),
                          ]
                        : const [],
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.white.withValues(alpha: 0.08),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: _chartLeftPadding,
                          interval: yInterval,
                          getTitlesWidget: (value, _) {
                            if (value < minY - 0.01 || value > maxY + 0.01) {
                              return const SizedBox.shrink();
                            }
                            return Text(
                              value.toStringAsFixed(0),
                              style: const TextStyle(
                                color: AppTheme.hintColor,
                                fontSize: 10,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: (widget.points.length / 4)
                              .clamp(1, widget.points.length)
                              .toDouble(),
                          getTitlesWidget: (value, _) {
                            final i = value.toInt();
                            if (i < 0 || i >= widget.points.length) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                DateFormat('d/M').format(widget.points[i].date),
                                style: const TextStyle(
                                  color: AppTheme.hintColor,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      enabled: true,
                      handleBuiltInTouches: false,
                      getTouchedSpotIndicator: (data, spotIndexes) {
                        return spotIndexes.map((index) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: widget.lineColor.withValues(alpha: 0.45),
                              strokeWidth: 1.5,
                              dashArray: [5, 4],
                            ),
                            FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, i) =>
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
