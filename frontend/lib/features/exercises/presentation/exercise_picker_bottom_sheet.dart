import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/label_translations.dart';
import '../data/exercise_provider.dart';
import '../domain/exercise_model.dart';
import 'create_exercise_screen.dart';
import 'exercise_detail_screen.dart';

/// Selector de ejercicios (biblioteca / crear rutina / estadísticas).
class ExercisePickerBottomSheet extends ConsumerStatefulWidget {
  final String title;
  final Set<int> excludeExerciseIds;

  const ExercisePickerBottomSheet({
    super.key,
    this.title = 'Ejercicios',
    this.excludeExerciseIds = const {},
  });

  @override
  ConsumerState<ExercisePickerBottomSheet> createState() =>
      _ExercisePickerBottomSheetState();
}

class _ExercisePickerBottomSheetState
    extends ConsumerState<ExercisePickerBottomSheet> {
  String _searchQuery = '';
  String _selectedMuscle = 'all';
  String _selectedEquipment = 'all';
  bool _onlyPopular = false;
  Timer? _searchDebounce;
  ScrollController? _listScrollController;

  final List<Map<String, String>> _muscleGroups = [
    {'id': 'all', 'name': 'Todos'},
    {'id': 'pecho', 'name': 'Pecho'},
    {'id': 'espalda', 'name': 'Espalda'},
    {'id': 'hombros', 'name': 'Hombros'},
    {'id': 'cuadriceps', 'name': 'Cuádriceps'},
    {'id': 'biceps', 'name': 'Bíceps'},
    {'id': 'triceps', 'name': 'Tríceps'},
    {'id': 'abdominales', 'name': 'Abs'},
    {'id': 'gluteos', 'name': 'Glúteos'},
    {'id': 'gemelos', 'name': 'Gemelos'},
    {'id': 'isquiotibiales', 'name': 'Femoral'},
    {'id': 'cardio', 'name': 'Cardio'},
  ];

  final List<Map<String, String>> _equipmentTypes = [
    {'id': 'all', 'name': 'Cualquiera'},
    {'id': 'barra', 'name': 'Barra'},
    {'id': 'mancuernas', 'name': 'Mancuernas'},
    {'id': 'maquina', 'name': 'Máquina'},
    {'id': 'polea', 'name': 'Polea'},
    {'id': 'peso_corporal', 'name': 'Peso Corporal'},
  ];

  bool _isSelectable(Exercise e) => !widget.excludeExerciseIds.contains(e.id);

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _applyServerFilters();
      ref.read(exerciseProvider.notifier).fetchPopularExercises();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _listScrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _bindScrollController(ScrollController controller) {
    if (_listScrollController == controller) return;
    _listScrollController?.removeListener(_onScroll);
    _listScrollController = controller;
    _listScrollController?.addListener(_onScroll);
  }

  void _onScroll() {
    if (_onlyPopular || _listScrollController == null) return;
    final position = _listScrollController!.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      ref.read(exerciseProvider.notifier).loadMore();
    }
  }

  void _applyServerFilters() {
    ref.read(exerciseProvider.notifier).fetchExercises(
          query: ExerciseQuery(
            search: _searchQuery,
            muscleGroup: _selectedMuscle,
            exerciseType: _selectedEquipment,
          ),
        );
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _searchDebounce?.cancel();
    if (_onlyPopular) return;
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _applyServerFilters();
    });
  }

  List<Exercise> _filteredPopular(List<Exercise> popular) {
    return popular.where((e) {
      if (!_isSelectable(e)) return false;
      final matchesSearch =
          e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle =
          _selectedMuscle == 'all' || e.muscleGroup == _selectedMuscle;
      final matchesEq =
          _selectedEquipment == 'all' || e.exerciseType == _selectedEquipment;
      return matchesSearch && matchesMuscle && matchesEq;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);

    final displayList = _onlyPopular
        ? _filteredPopular(state.popularExercises)
        : state.exercises.where(_isSelectable).toList();

    final visiblePopular =
        state.popularExercises.where(_isSelectable).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        _bindScrollController(scrollController);
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CreateExerciseScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nuevo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Buscar ejercicio...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryColor,
                          ),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _onlyPopular = !_onlyPopular),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: _onlyPopular
                              ? AppTheme.primaryColor
                              : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _onlyPopular
                                ? AppTheme.primaryColor
                                : Colors.white10,
                          ),
                        ),
                        child: Icon(
                          Icons.local_fire_department_outlined,
                          color:
                              _onlyPopular ? Colors.black : AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _muscleGroups.map((m) {
                    final isSelected = _selectedMuscle == m['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(m['name']!),
                        onSelected: (val) {
                          setState(() => _selectedMuscle = m['id']!);
                          if (!_onlyPopular) _applyServerFilters();
                        },
                        backgroundColor: AppTheme.cardColor,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        side: BorderSide.none,
                        showCheckmark: false,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _equipmentTypes.map((eq) {
                    final isSelected = _selectedEquipment == eq['id'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(eq['name']!),
                        onPressed: () {
                          setState(() => _selectedEquipment = eq['id']!);
                          if (!_onlyPopular) _applyServerFilters();
                        },
                        backgroundColor: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.2)
                            : AppTheme.cardColor.withValues(alpha: 0.5),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    if (visiblePopular.isNotEmpty &&
                        _searchQuery.isEmpty &&
                        !_onlyPopular &&
                        _selectedMuscle == 'all' &&
                        _selectedEquipment == 'all')
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.local_fire_department_outlined,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Más Populares',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        setState(() => _onlyPopular = true),
                                    child: const Text(
                                      'Ver todos',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 130,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: visiblePopular.length,
                                itemBuilder: (context, index) {
                                  final e = visiblePopular[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.of(context).pop(e),
                                    child: Container(
                                      width: 170,
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.1),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: AppTheme.surfaceColor,
                                                  child: e.gifUrl != null &&
                                                          e.gifUrl!.isNotEmpty
                                                      ? Image.network(
                                                          e.gifUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) =>
                                                              const Icon(
                                                            Icons.fitness_center,
                                                            color: AppTheme
                                                                .primaryColor,
                                                            size: 20,
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.fitness_center,
                                                          color: AppTheme
                                                              .primaryColor,
                                                          size: 20,
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  e.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            translateMuscleGroup(e.muscleGroup),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: AppTheme.primaryColor,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1, color: Colors.white10),
                          ],
                        ),
                      ),
                    if (state.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (displayList.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'No hay ejercicios con estos filtros',
                            style: TextStyle(color: AppTheme.hintColor),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final e = displayList[index];
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 8,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      color: AppTheme.cardColor,
                                      child: e.gifUrl != null &&
                                              e.gifUrl!.isNotEmpty
                                          ? Image.network(
                                              e.gifUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) =>
                                                  const Icon(
                                                Icons.fitness_center,
                                                color: AppTheme.primaryColor,
                                                size: 24,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.fitness_center,
                                              color: AppTheme.primaryColor,
                                              size: 24,
                                            ),
                                    ),
                                  ),
                                  title: Text(
                                    e.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            translateMuscleGroup(e.muscleGroup),
                                            style: const TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            translateEquipmentType(
                                              e.equipment ?? e.exerciseType,
                                            ),
                                            style: TextStyle(
                                              color: AppTheme.hintColor
                                                  .withValues(alpha: 0.8),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white24,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          final exercise =
                                              await Navigator.of(context)
                                                  .push<Exercise>(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ExerciseDetailScreen(
                                                exercise: e,
                                                showAddButton: true,
                                              ),
                                            ),
                                          );
                                          if (exercise != null &&
                                              context.mounted) {
                                            Navigator.of(context).pop(exercise);
                                          }
                                        },
                                      ),
                                      const Icon(
                                        Icons.add,
                                        color: AppTheme.primaryColor,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  onTap: () => Navigator.of(context).pop(e),
                                ),
                                const Divider(
                                  height: 1,
                                  color: Colors.white10,
                                  indent: 24,
                                  endIndent: 24,
                                ),
                              ],
                            );
                          },
                          childCount: displayList.length,
                        ),
                      ),
                    if (!_onlyPopular && state.isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
