import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../data/routine_template_provider.dart';
import '../domain/routine_model.dart';
import 'routine_template_detail_screen.dart';

class RoutineTemplateLibraryScreen extends ConsumerStatefulWidget {
  const RoutineTemplateLibraryScreen({super.key});

  @override
  ConsumerState<RoutineTemplateLibraryScreen> createState() =>
      _RoutineTemplateLibraryScreenState();
}

class _RoutineTemplateLibraryScreenState
    extends ConsumerState<RoutineTemplateLibraryScreen> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(routineTemplateProvider.notifier).fetchTemplates(),
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(routineTemplateProvider.notifier).fetchTemplates(search: value);
    });
  }

  Future<void> _showImportByCodeDialog() async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Importar con código',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(color: Colors.white, letterSpacing: 2),
          decoration: const InputDecoration(
            hintText: 'Ej. ABC12345',
            hintStyle: TextStyle(color: AppTheme.hintColor),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.hintColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Importar', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );

    if (code == null || code.isEmpty || !mounted) return;

    try {
      final routine =
          await ref.read(routineTemplateProvider.notifier).importByShareCode(code);
      if (!mounted) return;
      if (routine != null) {
        AppMessage.showSuccess(context, 'Rutina "${routine.name}" añadida');
      }
    } catch (_) {
      if (mounted) {
        AppMessage.showError(context, 'Código no válido o rutina ya importada');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(routineTemplateProvider);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Plantillas de rutina',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Importar con código',
            onPressed: _showImportByCodeDialog,
            icon: const Icon(Icons.qr_code_2_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar plantillas...',
                hintStyle: const TextStyle(color: AppTheme.hintColor),
                prefixIcon: const Icon(Icons.search, color: AppTheme.hintColor),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Oficiales Heft'),
                  selected: state.officialOnly,
                  onSelected: (selected) {
                    ref
                        .read(routineTemplateProvider.notifier)
                        .fetchTemplates(officialOnly: selected);
                  },
                  selectedColor: AppTheme.primaryColor.withValues(alpha: 0.25),
                  checkmarkColor: AppTheme.primaryColor,
                  labelStyle: TextStyle(
                    color: state.officialOnly ? AppTheme.primaryColor : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              color: AppTheme.primaryColor,
              onRefresh: () =>
                  ref.read(routineTemplateProvider.notifier).fetchTemplates(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(RoutineTemplateState state) {
    if (state.isLoading && state.templates.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (state.error != null && state.templates.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48, color: AppTheme.hintColor),
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.hintColor, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (state.templates.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.library_books_outlined, size: 48, color: AppTheme.hintColor),
          SizedBox(height: 16),
          Text(
            'No hay plantillas con esos filtros',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.hintColor),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.templates.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final template = state.templates[index];
        return _TemplateCard(
          template: template,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    RoutineTemplateDetailScreen(templateId: template.id),
              ),
            );
          },
        );
      },
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final RoutineTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (template.isOfficial)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Oficial',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (template.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  template.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.hintColor, fontSize: 13),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: AppTheme.hintColor),
                  const SizedBox(width: 4),
                  Text(
                    template.author.username,
                    style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${template.exerciseCount} ejercicios',
                    style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                  ),
                  if (template.timesImported > 0) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${template.timesImported} importaciones',
                      style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
