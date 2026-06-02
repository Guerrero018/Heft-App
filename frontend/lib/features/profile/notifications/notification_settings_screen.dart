import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_theme.dart';
import 'notification_preferences_model.dart';
import 'notification_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  AuthorizationStatus? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    if (!NotificationService.isFirebaseConfigured) {
      if (mounted) {
        setState(() => _permissionStatus = AuthorizationStatus.notDetermined);
      }
      return;
    }
    if (!NotificationService.isFirebaseAvailable) {
      await NotificationService.instance.init();
    }
    final status = await NotificationService.instance.getPermissionStatus();
    if (mounted) setState(() => _permissionStatus = status);
  }

  Future<void> _requestPermission() async {
    if (!NotificationService.isFirebaseConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Falta google-services.json. Sigue docs/FIREBASE_NOTIFICATIONS.md '
            'y ejecuta: dart run tool/generate_firebase_options.dart',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final status = await NotificationService.instance.requestPermissions();
    if (!mounted) return;

    setState(() => _permissionStatus = status);

    if (status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permisos de notificación activados')),
      );
    }
  }

  void _patch(NotificationPreferences updated) {
    ref.read(notificationPreferencesProvider.notifier).update(updated);
  }

  @override
  Widget build(BuildContext context) {
    final prefsState = ref.watch(notificationPreferencesProvider);
    final prefs = prefsState.prefs;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: prefsState.isLoading && prefs == null
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : prefs == null
              ? _ErrorView(
                  message: prefsState.error ?? 'Error al cargar preferencias',
                  onRetry: () =>
                      ref.read(notificationPreferencesProvider.notifier).load(),
                )
              : _buildBody(prefs),
    );
  }

  Widget _buildBody(NotificationPreferences prefs) {
    final firebaseReady = NotificationService.isFirebaseConfigured;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (!firebaseReady)
          const _FirebaseSetupBanner()
        else if (_permissionStatus != null &&
            _permissionStatus != AuthorizationStatus.authorized)
          _PermissionBanner(onRequest: _requestPermission),

        // Master switch
        _SectionCard(
          children: [
            _ToggleRow(
              icon: Icons.notifications_active,
              label: 'Activar notificaciones',
              value: prefs.allEnabled,
              onChanged: (v) => _patch(prefs.copyWith(allEnabled: v)),
            ),
          ],
        ),

        AnimatedOpacity(
          opacity: prefs.allEnabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: IgnorePointer(
            ignoring: !prefs.allEnabled,
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ---- Entrenamiento ----
                _SectionTitle(icon: Icons.fitness_center, title: 'Entrenamiento'),
                _SectionCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.alarm,
                      label: 'Recordatorio de entrenamiento',
                      value: prefs.workoutEnabled,
                      onChanged: (v) => _patch(prefs.copyWith(workoutEnabled: v)),
                    ),
                    if (prefs.workoutEnabled) ...[
                      const Divider(color: Colors.white10),
                      _TimePickerRow(
                        label: 'Hora del recordatorio',
                        hour: prefs.workoutHour,
                        minute: prefs.workoutMinute,
                        onPicked: (h, m) =>
                            _patch(prefs.copyWith(workoutHour: h, workoutMinute: m)),
                      ),
                      const Divider(color: Colors.white10),
                      _DayPickerRow(
                        selectedDays: prefs.workoutDays,
                        onChanged: (days) =>
                            _patch(prefs.copyWith(workoutDays: days)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ---- Progreso corporal ----
                _SectionTitle(icon: Icons.monitor_weight_outlined, title: 'Progreso corporal'),
                _SectionCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.straighten,
                      label: 'Recordatorio de medidas',
                      value: prefs.bodyProgressEnabled,
                      onChanged: (v) =>
                          _patch(prefs.copyWith(bodyProgressEnabled: v)),
                    ),
                    if (prefs.bodyProgressEnabled) ...[
                      const Divider(color: Colors.white10),
                      _DropdownRow<String>(
                        label: 'Frecuencia',
                        value: prefs.bodyProgressFrequency,
                        items: const [
                          DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                          DropdownMenuItem(
                              value: 'biweekly', child: Text('Quincenal')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Mensual')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            _patch(prefs.copyWith(bodyProgressFrequency: v));
                          }
                        },
                      ),
                      const Divider(color: Colors.white10),
                      _DropdownRow<int>(
                        label: 'Día',
                        value: prefs.bodyProgressDayOfWeek,
                        items: _weekdayItems(),
                        onChanged: (v) {
                          if (v != null) {
                            _patch(prefs.copyWith(bodyProgressDayOfWeek: v));
                          }
                        },
                      ),
                      const Divider(color: Colors.white10),
                      _TimePickerRow(
                        label: 'Hora',
                        hour: prefs.bodyProgressHour,
                        minute: prefs.bodyProgressMinute,
                        onPicked: (h, m) => _patch(
                            prefs.copyWith(
                                bodyProgressHour: h, bodyProgressMinute: m)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ---- Resumen semanal ----
                _SectionTitle(icon: Icons.bar_chart, title: 'Resumen semanal'),
                _SectionCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.summarize_outlined,
                      label: 'Resumen de la semana',
                      value: prefs.weeklySummaryEnabled,
                      onChanged: (v) =>
                          _patch(prefs.copyWith(weeklySummaryEnabled: v)),
                    ),
                    if (prefs.weeklySummaryEnabled) ...[
                      const Divider(color: Colors.white10),
                      _DropdownRow<int>(
                        label: 'Día',
                        value: prefs.weeklySummaryDayOfWeek,
                        items: _weekdayItems(),
                        onChanged: (v) {
                          if (v != null) {
                            _patch(prefs.copyWith(weeklySummaryDayOfWeek: v));
                          }
                        },
                      ),
                      const Divider(color: Colors.white10),
                      _TimePickerRow(
                        label: 'Hora',
                        hour: prefs.weeklySummaryHour,
                        minute: prefs.weeklySummaryMinute,
                        onPicked: (h, m) => _patch(
                            prefs.copyWith(
                                weeklySummaryHour: h, weeklySummaryMinute: m)),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 20),

                // ---- Motivación e inactividad ----
                _SectionTitle(
                    icon: Icons.local_fire_department,
                    title: 'Motivación e inactividad'),
                _SectionCard(
                  children: [
                    _ToggleRow(
                      icon: Icons.notifications_paused_outlined,
                      label: 'Aviso por inactividad',
                      value: prefs.inactivityEnabled,
                      onChanged: (v) =>
                          _patch(prefs.copyWith(inactivityEnabled: v)),
                    ),
                    if (prefs.inactivityEnabled) ...[
                      const Divider(color: Colors.white10),
                      _SliderRow(
                        label: 'Avisar tras',
                        value: prefs.inactivityThresholdDays.toDouble(),
                        min: 1,
                        max: 14,
                        unit: 'días sin entrenar',
                        onChanged: (v) => _patch(
                            prefs.copyWith(inactivityThresholdDays: v.round())),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<DropdownMenuItem<int>> _weekdayItems() {
    const days = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'
    ];
    return List.generate(
      7,
      (i) => DropdownMenuItem(value: i, child: Text(days[i])),
    );
  }
}

// ============================================================================
// Subwidgets
// ============================================================================

class _FirebaseSetupBanner extends StatelessWidget {
  const _FirebaseSetupBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off_outlined, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firebase no configurado en esta build',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Para push reales: descarga google-services.json del proyecto '
                  'Firebase y colócalo en frontend/android/app/. Luego ejecuta '
                  'dart run tool/generate_firebase_options.dart y vuelve a '
                  'compilar la app. Guía: docs/FIREBASE_NOTIFICATIONS.md',
                  style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onRequest;
  const _PermissionBanner({required this.onRequest});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permisos de notificación desactivados',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Activa los permisos para recibir recordatorios.',
                  style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRequest,
                  child: const Text(
                    'Activar permisos',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionTitle({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: children
            .map(
              (child) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: child,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeThumbColor: AppTheme.primaryColor,
      secondary: Icon(icon, color: AppTheme.primaryColor, size: 22),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _TimePickerRow extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onPicked;

  const _TimePickerRow({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onPicked,
  });

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: hour, minute: minute),
            builder: (context, child) => Theme(
              data: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppTheme.primaryColor,
                  surface: AppTheme.cardColor,
                ),
              ),
              child: child!,
            ),
          );
          if (picked != null) onPicked(picked.hour, picked.minute);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            _fmt(hour, minute),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayPickerRow extends StatelessWidget {
  final List<int> selectedDays;
  final ValueChanged<List<int>> onChanged;

  const _DayPickerRow({required this.selectedDays, required this.onChanged});

  static const _labels = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Text(
            'Días',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const Spacer(),
          ...List.generate(7, (i) {
            final selected = selectedDays.contains(i);
            return GestureDetector(
              onTap: () {
                final days = List<int>.from(selectedDays);
                selected ? days.remove(i) : days.add(i);
                onChanged(days..sort());
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(left: 6),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      color: selected ? Colors.black : AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
      trailing: DropdownButton<T>(
        value: value,
        dropdownColor: AppTheme.cardColor,
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.expand_more, color: AppTheme.hintColor),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
              Text(
                '${value.round()} $unit',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.hintColor),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor),
              onPressed: onRetry,
              child: const Text('Reintentar',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
