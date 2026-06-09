import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../exercises/data/exercise_provider.dart';
import '../../profile/widgets/settings_ui.dart';
import '../../routines/data/routine_provider.dart';
import '../data/export_api_service.dart';
import '../data/export_provider.dart';

class ExportDataScreen extends ConsumerStatefulWidget {
  const ExportDataScreen({super.key});

  @override
  ConsumerState<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends ConsumerState<ExportDataScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(routineProvider.notifier).fetchRoutines(silent: true);
      ref.read(exerciseProvider.notifier).fetchExercises();
      ref.read(exportProvider.notifier).refreshPreview();
    });
  }

  ExportRequest get _request => ref.read(exportProvider).request;

  void _patchRequest(ExportRequest Function(ExportRequest current) patch) {
    ref.read(exportProvider.notifier).updateRequest(patch(_request));
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _request.dateFrom : _request.dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    _patchRequest(
      (current) => isFrom
          ? ExportRequest(
              format: current.format,
              includeWorkouts: current.includeWorkouts,
              includeBodyMeasures: current.includeBodyMeasures,
              includePrs: current.includePrs,
              dateFrom: picked,
              dateTo: current.dateTo,
              routineId: current.routineId,
              exerciseId: current.exerciseId,
            )
          : ExportRequest(
              format: current.format,
              includeWorkouts: current.includeWorkouts,
              includeBodyMeasures: current.includeBodyMeasures,
              includePrs: current.includePrs,
              dateFrom: current.dateFrom,
              dateTo: picked,
              routineId: current.routineId,
              exerciseId: current.exerciseId,
            ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sin limite';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final exportState = ref.watch(exportProvider);
    final request = exportState.request;
    final routines = ref.watch(routineProvider).routines;
    final exercises = ref.watch(exerciseProvider).exercises;
    final preview = exportState.preview;

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
          'Exportar mis datos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const SettingsInfoBanner(
            icon: Icons.download_outlined,
            message:
                'Descarga tu historial de entrenamientos, medidas corporales y records personales. '
                'Aplica filtros y elige CSV o un informe PDF con el estilo Heft.',
          ),
          const SizedBox(height: 20),
          const SettingsSectionTitle(icon: Icons.tune, title: 'Formato'),
          SettingsSectionCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'csv', label: Text('CSV')),
                    ButtonSegment(value: 'pdf', label: Text('PDF')),
                  ],
                  selected: {request.format},
                  onSelectionChanged: (selection) {
                    _patchRequest(
                      (current) => ExportRequest(
                        format: selection.first,
                        includeWorkouts: current.includeWorkouts,
                        includeBodyMeasures: current.includeBodyMeasures,
                        includePrs: current.includePrs,
                        dateFrom: current.dateFrom,
                        dateTo: current.dateTo,
                        routineId: current.routineId,
                        exerciseId: current.exerciseId,
                      ),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryColor;
                      }
                      return AppTheme.cardColor;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black;
                      }
                      return Colors.white;
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SettingsSectionTitle(icon: Icons.dataset_outlined, title: 'Datos a incluir'),
          SettingsSectionCard(
            children: [
              _DatasetToggle(
                label: 'Historial de entrenamientos',
                subtitle: 'Series, pesos, reps y rutinas',
                value: request.includeWorkouts,
                onChanged: (value) => _patchRequest(
                  (current) => ExportRequest(
                    format: current.format,
                    includeWorkouts: value,
                    includeBodyMeasures: current.includeBodyMeasures,
                    includePrs: current.includePrs,
                    dateFrom: current.dateFrom,
                    dateTo: current.dateTo,
                    routineId: current.routineId,
                    exerciseId: current.exerciseId,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              _DatasetToggle(
                label: 'Medidas corporales',
                subtitle: 'Peso y medidas registradas',
                value: request.includeBodyMeasures,
                onChanged: (value) => _patchRequest(
                  (current) => ExportRequest(
                    format: current.format,
                    includeWorkouts: current.includeWorkouts,
                    includeBodyMeasures: value,
                    includePrs: current.includePrs,
                    dateFrom: current.dateFrom,
                    dateTo: current.dateTo,
                    routineId: current.routineId,
                    exerciseId: current.exerciseId,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              _DatasetToggle(
                label: 'Records personales',
                subtitle: 'Mejor peso por ejercicio en el rango',
                value: request.includePrs,
                onChanged: (value) => _patchRequest(
                  (current) => ExportRequest(
                    format: current.format,
                    includeWorkouts: current.includeWorkouts,
                    includeBodyMeasures: current.includeBodyMeasures,
                    includePrs: value,
                    dateFrom: current.dateFrom,
                    dateTo: current.dateTo,
                    routineId: current.routineId,
                    exerciseId: current.exerciseId,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const SettingsSectionTitle(icon: Icons.filter_alt_outlined, title: 'Filtros'),
          SettingsSectionCard(
            children: [
              _FilterRow(
                label: 'Desde',
                value: _formatDate(request.dateFrom),
                onTap: () => _pickDate(isFrom: true),
                onClear: request.dateFrom != null
                    ? () => _patchRequest(
                        (current) => ExportRequest(
                          format: current.format,
                          includeWorkouts: current.includeWorkouts,
                          includeBodyMeasures: current.includeBodyMeasures,
                          includePrs: current.includePrs,
                          dateTo: current.dateTo,
                          routineId: current.routineId,
                          exerciseId: current.exerciseId,
                        ),
                      )
                    : null,
              ),
              const Divider(color: Colors.white10),
              _FilterRow(
                label: 'Hasta',
                value: _formatDate(request.dateTo),
                onTap: () => _pickDate(isFrom: false),
                onClear: request.dateTo != null
                    ? () => _patchRequest(
                        (current) => ExportRequest(
                          format: current.format,
                          includeWorkouts: current.includeWorkouts,
                          includeBodyMeasures: current.includeBodyMeasures,
                          includePrs: current.includePrs,
                          dateFrom: current.dateFrom,
                          routineId: current.routineId,
                          exerciseId: current.exerciseId,
                        ),
                      )
                    : null,
              ),
              const Divider(color: Colors.white10),
              _DropdownFilter(
                label: 'Rutina',
                value: request.routineId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todas las rutinas')),
                  ...routines.map(
                    (routine) => DropdownMenuItem<int?>(
                      value: routine.id,
                      child: Text(routine.name),
                    ),
                  ),
                ],
                onChanged: (value) => _patchRequest(
                  (current) => ExportRequest(
                    format: current.format,
                    includeWorkouts: current.includeWorkouts,
                    includeBodyMeasures: current.includeBodyMeasures,
                    includePrs: current.includePrs,
                    dateFrom: current.dateFrom,
                    dateTo: current.dateTo,
                    routineId: value,
                    exerciseId: current.exerciseId,
                  ),
                ),
              ),
              const Divider(color: Colors.white10),
              _DropdownFilter(
                label: 'Ejercicio',
                value: request.exerciseId,
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Todos los ejercicios')),
                  ...exercises.map(
                    (exercise) => DropdownMenuItem<int?>(
                      value: exercise.id,
                      child: Text(exercise.name),
                    ),
                  ),
                ],
                onChanged: (value) => _patchRequest(
                  (current) => ExportRequest(
                    format: current.format,
                    includeWorkouts: current.includeWorkouts,
                    includeBodyMeasures: current.includeBodyMeasures,
                    includePrs: current.includePrs,
                    dateFrom: current.dateFrom,
                    dateTo: current.dateTo,
                    routineId: current.routineId,
                    exerciseId: value,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _PreviewCard(
            isLoading: exportState.isPreviewLoading,
            preview: preview,
            error: exportState.error,
          ),
          if (exportState.error != null &&
              exportState.preview != null) ...[
            const SizedBox(height: 12),
            Text(
              exportState.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: exportState.isExporting ||
                      exportState.isPreviewLoading ||
                      (preview?.total ?? 0) == 0
                  ? null
                  : () => ref.read(exportProvider.notifier).exportAndShare(),
              icon: exportState.isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : Icon(request.format == 'pdf' ? Icons.picture_as_pdf : Icons.table_chart),
              label: Text(
                exportState.isExporting
                    ? 'Generando...'
                    : request.format == 'pdf'
                        ? 'Exportar PDF'
                        : 'Exportar CSV',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatasetToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _DatasetToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppTheme.hintColor, fontSize: 12)),
      value: value,
      activeThumbColor: AppTheme.primaryColor,
      onChanged: onChanged,
    );
  }
}

class _FilterRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterRow({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: const TextStyle(color: Colors.white)),
      subtitle: Text(value, style: const TextStyle(color: AppTheme.primaryColor)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null)
            IconButton(
              icon: const Icon(Icons.close, color: AppTheme.hintColor, size: 18),
              onPressed: onClear,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor, size: 20),
            onPressed: onTap,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final int? value;
  final List<DropdownMenuItem<int?>> items;
  final ValueChanged<int?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String _labelFor(int? id) {
    for (final item in items) {
      if (item.value == id && item.child is Text) {
        return (item.child as Text).data ?? '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            isExpanded: true,
            initialValue: value,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: AppTheme.cardColor,
            style: const TextStyle(color: Colors.white),
            selectedItemBuilder: (context) => items.map((item) {
              final text = item.child is Text
                  ? (item.child as Text).data ?? ''
                  : _labelFor(item.value);
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              );
            }).toList(),
            items: items
                .map(
                  (item) => DropdownMenuItem<int?>(
                    value: item.value,
                    child: item.child is Text
                        ? Text(
                            (item.child as Text).data ?? '',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        : item.child,
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final bool isLoading;
  final ExportPreview? preview;
  final String? error;

  const _PreviewCard({
    required this.isLoading,
    required this.preview,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa',
            style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            const LinearProgressIndicator(color: AppTheme.primaryColor, minHeight: 2)
          else if (error != null && preview == null)
            Text(
              error!,
              style: const TextStyle(color: Colors.redAccent, height: 1.4),
            )
          else if (preview == null)
            const Text('No disponible', style: TextStyle(color: AppTheme.hintColor))
          else ...[
            _PreviewLine(label: 'Entrenamientos', count: preview!.workoutsCount),
            _PreviewLine(label: 'Medidas', count: preview!.bodyMeasuresCount),
            _PreviewLine(label: 'Records', count: preview!.prsCount),
            const SizedBox(height: 8),
            Text(
              preview!.total == 0
                  ? 'No hay registros con estos filtros.'
                  : '${preview!.total} registros listos para exportar.',
              style: TextStyle(
                color: preview!.total == 0 ? Colors.orangeAccent : AppTheme.hintColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  final String label;
  final int count;

  const _PreviewLine({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
