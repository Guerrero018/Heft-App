import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/body_measure_model.dart';
import '../../domain/muscle_group_metrics.dart';
import '../widgets/scrubbable_measure_line_chart.dart';
import '../widgets/body_progress_empty.dart';

class MuscleStatsTab extends StatefulWidget {
  final List<BodyMeasureEntry> entries;

  const MuscleStatsTab({super.key, required this.entries});

  @override
  State<MuscleStatsTab> createState() => _MuscleStatsTabState();
}

class _MuscleStatsTabState extends State<MuscleStatsTab> {
  String? _selectedGroupId;

  MuscleGroupMetric _resolveSelected(
    List<MuscleGroupMetric> groups,
    List<MuscleGroupMetric> chartable,
  ) {
    if (_selectedGroupId != null) {
      for (final g in groups) {
        if (g.id == _selectedGroupId) return g;
      }
    }
    if (chartable.isNotEmpty) return chartable.first;
    return groups.first;
  }

  @override
  Widget build(BuildContext context) {
    final groups = MuscleGroupMetricsBuilder.fromEntries(widget.entries);
    final chartable = groups.where((g) => g.points.length >= 2).toList();

    if (groups.isEmpty) {
      return const BodyProgressEmpty(
        icon: Icons.bar_chart,
        message:
            'Registra medidas corporales para ver cómo evolucionan pecho, brazos, piernas y más.',
      );
    }

    final selected = _resolveSelected(groups, chartable);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        const Text(
          'Evolución por zona',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cada gráfico muestra el cambio en centímetros a lo largo del tiempo.',
          style: TextStyle(color: AppTheme.hintColor, fontSize: 13, height: 1.35),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final g = groups[i];
              final isSelected = g.id == selected.id;
              return FilterChip(
                label: Text(g.label),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedGroupId = g.id),
                avatar: Icon(g.icon, size: 16, color: isSelected ? Colors.black : g.color),
                backgroundColor: AppTheme.cardColor,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                showCheckmark: false,
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : Colors.white10,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        _SummaryCard(group: selected),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(selected.icon, color: selected.color, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    selected.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ScrubbableMeasureLineChart(
                points: selected.points,
                lineColor: selected.color,
                headerLabel: 'Arrastra sobre el gráfico',
              ),
            ],
          ),
        ),
        if (chartable.length > 1) ...[
          const SizedBox(height: 28),
          const Text(
            'Resumen por zona',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...chartable.map((g) => _MiniTrendTile(group: g)),
        ],
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final MuscleGroupMetric group;

  const _SummaryCard({required this.group});

  @override
  Widget build(BuildContext context) {
    final delta = group.deltaCm;
    final hasTrend = group.points.length >= 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: group.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasTrend ? '${group.lastValue!.toStringAsFixed(1)} cm' : '—',
                  style: TextStyle(
                    color: group.color,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  hasTrend
                      ? 'Último · ${DateFormat('d MMM yyyy', 'es').format(group.points.last.date)}'
                      : 'Un solo registro',
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          if (delta != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      delta >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: delta >= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
                      size: 20,
                    ),
                    Text(
                      '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} cm',
                      style: TextStyle(
                        color: delta >= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'desde el primer registro',
                  style: TextStyle(color: AppTheme.hintColor, fontSize: 11),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MiniTrendTile extends StatelessWidget {
  final MuscleGroupMetric group;

  const _MiniTrendTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final delta = group.deltaCm ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(group.icon, color: group.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              group.label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            '${group.firstValue!.toStringAsFixed(0)} → ${group.lastValue!.toStringAsFixed(0)} cm',
            style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
            style: TextStyle(
              color: delta >= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
