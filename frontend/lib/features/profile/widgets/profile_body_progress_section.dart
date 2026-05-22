import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../body_progress/data/body_progress_provider.dart';
import '../../body_progress/domain/body_measure_model.dart';
import '../../body_progress/presentation/add_body_entry_screen.dart';
import '../../body_progress/presentation/body_progress_screen.dart';
import '../../body_progress/presentation/widgets/entry_measure_chips.dart';

/// Bloque compacto de progreso corporal para el perfil.
class ProfileBodyProgressSection extends ConsumerWidget {
  const ProfileBodyProgressSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bodyProgressProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: AppTheme.primaryColor, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tu progreso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => _openAdd(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Registrar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.isLoading && state.entries.isEmpty)
            const _ProgressCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            )
          else if (state.error != null && state.entries.isEmpty)
            _ProgressCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppTheme.hintColor, fontSize: 13, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () =>
                          ref.read(bodyProgressProvider.notifier).loadAll(force: true),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          else if (state.entries.isEmpty)
            _ProgressCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Registra peso, fotos y medidas para ver tu evolución.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openAdd(context, ref),
                      icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            )
          else
            _FilledProgressSummary(
              entries: state.entries,
              onOpenDetail: () => _openDetail(context),
            ),
        ],
      ),
    );
  }

  Future<void> _openAdd(BuildContext context, WidgetRef ref) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddBodyEntryScreen()),
    );
    if (saved == true) {
      await ref.read(bodyProgressProvider.notifier).loadAll(force: true);
    }
  }

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BodyProgressScreen()),
    );
  }
}

class _FilledProgressSummary extends StatelessWidget {
  final List<BodyMeasureEntry> entries;
  final VoidCallback onOpenDetail;

  const _FilledProgressSummary({
    required this.entries,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final latest = entries.first;
    final thumbs = latest.photoUrls.take(4).toList();

    double? weightDelta;
    if (entries.length >= 2) {
      weightDelta = latest.weight - entries[1].weight;
    }

    return Column(
      children: [
        _ProgressCard(
          child: InkWell(
            onTap: onOpenDetail,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${latest.weight.toStringAsFixed(1)} kg',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('d MMM yyyy', 'es').format(latest.date),
                              style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (weightDelta != null) _DeltaBadge(delta: weightDelta),
                      const Icon(Icons.chevron_right, color: AppTheme.hintColor),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: Colors.white12, height: 1),
                  const SizedBox(height: 12),
                  EntryMeasureChips(entry: latest, compact: true),
                  if (thumbs.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 64,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: thumbs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) => ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 48,
                            height: 64,
                            child: CachedNetworkImage(
                              imageUrl: thumbs[i],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  final double delta;

  const _DeltaBadge({required this.delta});

  @override
  Widget build(BuildContext context) {
    final isDown = delta < 0;
    final color = isDown ? Colors.lightGreenAccent : Colors.orangeAccent;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDown ? Icons.arrow_downward : Icons.arrow_upward,
            size: 14,
            color: color,
          ),
          Text(
            '${delta.abs().toStringAsFixed(1)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final Widget child;

  const _ProgressCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: child,
    );
  }
}
