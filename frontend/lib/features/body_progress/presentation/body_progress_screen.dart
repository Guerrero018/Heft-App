import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../auth/auth_provider.dart';
import '../data/body_progress_provider.dart';
import '../domain/body_measure_model.dart';
import 'add_body_entry_screen.dart';

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
                  Tab(text: 'Peso'),
                  Tab(text: 'Fotos'),
                  Tab(text: 'Medidas'),
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
                    children: [
                      _WeightTab(history: state.weightHistory, entries: state.entries),
                      _PhotosTab(entries: state.photoEntries),
                      _MeasurementsTab(entries: state.entries),
                    ],
                  ),
      ),
    );
  }
}

class _WeightTab extends StatelessWidget {
  final List<WeightHistoryPoint> history;
  final List<BodyMeasureEntry> entries;

  const _WeightTab({required this.history, required this.entries});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const _EmptyState(
        icon: Icons.show_chart,
        message: 'Aún no hay registros de peso.\nPulsa «Registrar» para empezar.',
      );
    }

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();
    final minY = history.map((e) => e.weight).reduce((a, b) => a < b ? a : b) - 2;
    final maxY = history.map((e) => e.weight).reduce((a, b) => a > b ? a : b) + 2;
    final latest = entries.isNotEmpty ? entries.first : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      children: [
        if (latest != null)
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
                Column(
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
              ],
            ),
          ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withOpacity(0.08),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(0),
                      style: const TextStyle(color: AppTheme.hintColor, fontSize: 11),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (history.length / 4).clamp(1, history.length).toDouble(),
                    getTitlesWidget: (value, _) {
                      final i = value.toInt();
                      if (i < 0 || i >= history.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          DateFormat('d/M').format(history[i].date),
                          style: const TextStyle(color: AppTheme.hintColor, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: AppTheme.primaryColor.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Historial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...entries.map((e) => _EntryTile(entry: e, showWeight: true)),
      ],
    );
  }
}

class _PhotosTab extends ConsumerWidget {
  final List<BodyMeasureEntry> entries;

  const _PhotosTab({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const _EmptyState(
        icon: Icons.photo_camera_outlined,
        message: 'Sin fotos de progreso.\nAñade una al crear un registro.',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return GestureDetector(
          onLongPress: () => _confirmDelete(context, ref, entry),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: entry.photoUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: AppTheme.cardColor),
                  errorWidget: (_, __, ___) => const Icon(Icons.broken_image, color: AppTheme.hintColor),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      '${entry.weight.toStringAsFixed(1)} kg · ${DateFormat('d MMM yy', 'es').format(entry.date)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MeasurementsTab extends ConsumerWidget {
  final List<BodyMeasureEntry> entries;

  const _MeasurementsTab({required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final withMeasures = entries.where((e) => e.hasBodyMeasurements).toList();
    if (withMeasures.isEmpty) {
      return const _EmptyState(
        icon: Icons.straighten,
        message: 'Sin medidas corporales.\nActívalas al registrar un check-in.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
      itemCount: withMeasures.length,
      itemBuilder: (context, index) {
        final entry = withMeasures[index];
        return Card(
          color: AppTheme.cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('d MMMM yyyy', 'es').format(entry.date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (entry.neckCm != null) _chip('Cuello', entry.neckCm!),
                    if (entry.chestCm != null) _chip('Pecho', entry.chestCm!),
                    if (entry.waistCm != null) _chip('Cintura', entry.waistCm!),
                    if (entry.hipsCm != null) _chip('Cadera', entry.hipsCm!),
                    if (entry.shouldersCm != null) _chip('Hombros', entry.shouldersCm!),
                    if (entry.bicepLeftCm != null) _chip('Brazo izq.', entry.bicepLeftCm!),
                    if (entry.bicepRightCm != null) _chip('Brazo der.', entry.bicepRightCm!),
                    if (entry.thighLeftCm != null) _chip('Muslo izq.', entry.thighLeftCm!),
                    if (entry.thighRightCm != null) _chip('Muslo der.', entry.thighRightCm!),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => _confirmDelete(context, ref, entry),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _chip(String label, double cm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$label: ${cm.toStringAsFixed(1)} cm',
        style: const TextStyle(color: Colors.white, fontSize: 13),
      ),
    );
  }
}

class _EntryTile extends ConsumerWidget {
  final BodyMeasureEntry entry;
  final bool showWeight;

  const _EntryTile({required this.entry, this.showWeight = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      tileColor: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        DateFormat('d MMM yyyy', 'es').format(entry.date),
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      subtitle: showWeight
          ? Text(
              '${entry.weight.toStringAsFixed(1)} kg',
              style: const TextStyle(color: AppTheme.primaryColor),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: AppTheme.hintColor),
        onPressed: () => _confirmDelete(context, ref, entry),
      ),
    );
  }
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  BodyMeasureEntry entry,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppTheme.cardColor,
      title: const Text('Eliminar registro', style: TextStyle(color: Colors.white)),
      content: const Text(
        '¿Eliminar este registro de progreso?',
        style: TextStyle(color: AppTheme.hintColor),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );

  if (confirmed == true && context.mounted) {
    final ok = await ref.read(bodyProgressProvider.notifier).deleteEntry(entry.id);
    if (context.mounted) {
      if (ok) {
        await ref.read(authProvider.notifier).syncProfile();
        AppMessage.showSuccess(context, 'Registro eliminado');
      } else {
        AppMessage.showError(context, ref.read(bodyProgressProvider).error ?? 'Error');
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppTheme.hintColor.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.hintColor, height: 1.4),
            ),
          ],
        ),
      ),
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
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.hintColor)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}
