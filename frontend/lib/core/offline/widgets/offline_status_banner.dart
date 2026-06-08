import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connectivity_provider.dart';
import '../offline_sync_provider.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(offlineSyncProvider);

    final showOffline = connectivity.isOffline;
    final showPending = syncState.pendingCount > 0;
    if (!showOffline && !showPending) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    String message;
    IconData icon;
    Color background;
    Color foreground;

    if (syncState.isSyncing) {
      message = 'Sincronizando entrenamientos...';
      icon = Icons.sync;
      background = colorScheme.primaryContainer;
      foreground = colorScheme.onPrimaryContainer;
    } else if (showOffline && showPending) {
      message =
          'Sin conexión · ${syncState.pendingCount} entreno(s) pendiente(s) de sincronizar';
      icon = Icons.cloud_off_outlined;
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
    } else if (showOffline) {
      message = 'Sin conexión · tus datos se guardan en el dispositivo';
      icon = Icons.cloud_off_outlined;
      background = colorScheme.errorContainer;
      foreground = colorScheme.onErrorContainer;
    } else {
      message =
          '${syncState.pendingCount} entreno(s) pendiente(s) de sincronizar';
      icon = Icons.cloud_upload_outlined;
      background = colorScheme.tertiaryContainer;
      foreground = colorScheme.onTertiaryContainer;
    }

    return Material(
      color: background,
      child: SafeArea(
        bottom: false,
        child: InkWell(
          onTap: showPending && !syncState.isSyncing
              ? () => ref.read(offlineSyncProvider.notifier).syncPendingWorkouts()
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (syncState.isSyncing)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  )
                else
                  Icon(icon, size: 18, color: foreground),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (showPending && !syncState.isSyncing)
                  Icon(Icons.refresh, size: 18, color: foreground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
