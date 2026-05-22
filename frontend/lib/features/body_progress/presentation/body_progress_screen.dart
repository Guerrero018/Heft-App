import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../data/body_progress_chart_scrub_provider.dart';
import '../data/body_progress_provider.dart';
import '../domain/body_measure_model.dart';
import '../domain/muscle_group_metrics.dart';
import 'add_body_entry_screen.dart';
import 'body_progress_delete.dart';
import 'tabs/muscle_stats_tab.dart';
import 'tabs/photo_album_tab.dart';
import 'widgets/body_progress_empty.dart';
import 'widgets/history_entry_card.dart';
import 'widgets/scrubbable_measure_line_chart.dart';

class BodyProgressScreen extends ConsumerStatefulWidget {
  const BodyProgressScreen({super.key});

  @override
  ConsumerState<BodyProgressScreen> createState() => _BodyProgressScreenState();
}

class _BodyProgressScreenState extends ConsumerState<BodyProgressScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(bodyProgressProvider.notifier).loadAll(force: true),
    );
  }

  Future<void> _openAddEntry() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddBodyEntryScreen()),
    );
    if (saved == true && mounted) {
      AppMessage.showSuccess(context, 'Registro guardado');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bodyProgressProvider);
    final chartScrubActive = ref.watch(bodyProgressChartScrubProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Progreso físico',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  color: AppTheme.primaryColor,
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.hintColor,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: 'Historial'),
                  Tab(text: 'Estadísticas'),
                  Tab(text: 'Álbum'),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: state.isLoading ? null : _openAddEntry,
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Registrar', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: state.isLoading && state.entries.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            : state.error != null && state.entries.isEmpty
                ? _ErrorView(
                    message: state.error!,
                    onRetry: () => ref.read(bodyProgressProvider.notifier).loadAll(force: true),
                  )
                : TabBarView(
                    physics: chartScrubActive
                        ? const NeverScrollableScrollPhysics()
                        : const ClampingScrollPhysics(),
                    children: [
                      _HistorialTab(history: state.weightHistory, entries: state.entries),
                      MuscleStatsTab(entries: state.entries),
                      PhotoAlbumTab(entries: state.entries),
                    ],
                  ),
      ),
    );
  }
}

class _HistorialTab extends ConsumerWidget {
  final List<WeightHistoryPoint> history;
  final List<BodyMeasureEntry> entries;

  const _HistorialTab({required this.history, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return const BodyProgressEmpty(
        icon: Icons.history,
        message: 'Aún no hay registros.\nPulsa «Registrar» para empezar.',
      );
    }

    final latest = entries.first;
    final weightPoints = history
        .map(
          (h) => MeasureSeriesPoint(
            date: h.date,
            valueCm: h.weight,
            entryId: 0,
          ),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              const Icon(Icons.monitor_weight, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Último registro', style: TextStyle(color: AppTheme.hintColor)),
                    Text(
                      '${latest.weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('d MMM yyyy', 'es').format(latest.date),
                      style: const TextStyle(color: AppTheme.hintColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ScrubbableMeasureLineChart(
          points: weightPoints,
          lineColor: AppTheme.primaryColor,
          unitLabel: 'kg',
          headerLabel: 'Evolución del peso',
        ),
        const SizedBox(height: 24),
        const Text(
          'Todos los registros',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map(
          (e) => HistoryEntryCard(
            entry: e,
            onDelete: () => confirmDeleteBodyEntry(context, ref, e),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.hintColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
