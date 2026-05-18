import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/label_translations.dart';
import '../data/routine_provider.dart';
import '../../exercises/data/exercise_provider.dart';
import '../../exercises/domain/exercise_model.dart';
import '../../exercises/presentation/exercise_detail_screen.dart';
import '../../exercises/presentation/create_exercise_screen.dart';
import '../domain/routine_model.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  final Routine? existingRoutine;
  
  const CreateRoutineScreen({super.key, this.existingRoutine});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<SelectedExercise> _selectedExercises = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingRoutine != null) {
      _nameController.text = widget.existingRoutine!.name;
      _descriptionController.text = widget.existingRoutine!.description;
      for (final e in widget.existingRoutine!.exercises) {
        _selectedExercises.add(SelectedExercise(
          exercise: Exercise(
            id: e.exerciseId,
            name: e.exerciseName,
            muscleGroup: e.muscleGroup,
            externalId: e.externalId,
            gifUrl: e.gifUrl,
            exerciseType: 'otro', // fallback field for filters
            isGlobal: true, // not strictly used but required by model
          ),
          sets: e.targetSets,
          reps: e.targetReps,
          weight: e.targetWeight,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    setState(() {
      _selectedExercises.add(SelectedExercise(
        exercise: exercise,
        sets: 3,
        reps: 10,
        weight: 0,
      ));
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, indica un nombre para la rutina')),
      );
      return;
    }

    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos un ejercicio')),
      );
      return;
    }

    final exercisesData = _selectedExercises.asMap().entries.map((entry) {
      final index = entry.key;
      final e = entry.value;
      return {
        'exercise': e.exercise.id,
        'order': index,
        'target_sets': e.sets,
        'target_reps': e.reps,
        'target_weight': e.weight,
      };
    }).toList();

    try {
      if (widget.existingRoutine == null) {
        await ref.read(routineProvider.notifier).createRoutineWithExercises(
          name,
          _descriptionController.text.trim(),
          exercisesData,
        );
      } else {
        await ref.read(routineProvider.notifier).updateRoutine(
          widget.existingRoutine!.id!,
          name,
          _descriptionController.text.trim(),
          exercisesData,
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.existingRoutine == null ? 'Rutina creada con éxito' : 'Rutina actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar la rutina: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.existingRoutine == null ? 'Nueva Rutina' : 'Editar Rutina', 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Nombre de la rutina (ej: Empuje A)',
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Descripción (opcional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ejercicios',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => _showExercisePicker(context),
                  icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_selectedExercises.isEmpty)
              _buildEmptyExercises()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedExercises.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return _buildExerciseTile(index);
                },
              ),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyExercises() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center, color: AppTheme.hintColor.withOpacity(0.3), size: 48),
          const SizedBox(height: 16),
          const Text('Añade ejercicios a tu rutina', style: TextStyle(color: AppTheme.hintColor)),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(int index) {
    final item = _selectedExercises[index];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('${index + 1}.', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.exercise.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              IconButton(
                onPressed: () => _removeExercise(index),
                icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
          const Divider(height: 24, color: Colors.white10),
          Row(
            children: [
              _buildInputColumn('Series', (val) => item.sets = int.tryParse(val) ?? 0, item.sets.toString()),
              const SizedBox(width: 16),
              _buildInputColumn('Repeticiones', (val) => item.reps = int.tryParse(val) ?? 0, item.reps.toString()),
              const SizedBox(width: 16),
              _buildInputColumn('Peso (kg)', (val) => item.weight = double.tryParse(val) ?? 0, item.weight.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputColumn(String label, Function(String) onChanged, String initialValue) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.hintColor, fontSize: 12)),
          const SizedBox(height: 4),
          TextFormField(
            initialValue: initialValue,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: onChanged,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              fillColor: Colors.black26,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  void _showExercisePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => const ExercisePickerBottomSheet(),
    ).then((selected) {
      if (selected != null && selected is Exercise) {
        _addExercise(selected);
      }
    });
  }
}

class SelectedExercise {
  final Exercise exercise;
  int sets;
  int reps;
  double weight;

  SelectedExercise({required this.exercise, required this.sets, required this.reps, required this.weight});
}

class ExercisePickerBottomSheet extends ConsumerStatefulWidget {
  const ExercisePickerBottomSheet({super.key});

  @override
  ConsumerState<ExercisePickerBottomSheet> createState() => _ExercisePickerBottomSheetState();
}

class _ExercisePickerBottomSheetState extends ConsumerState<ExercisePickerBottomSheet> {
  String _searchQuery = '';
  String _selectedMuscle = 'all';
  String _selectedEquipment = 'all';
  bool _onlyPopular = false;

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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(exerciseProvider.notifier).fetchExercises();
      ref.read(exerciseProvider.notifier).fetchPopularExercises();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);
    
    final baseList = _onlyPopular ? state.popularExercises : state.exercises;

    final filtered = baseList.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == 'all' || e.muscleGroup == _selectedMuscle;
      final matchesEq = _selectedEquipment == 'all' || e.exerciseType == _selectedEquipment;
      return matchesSearch && matchesMuscle && matchesEq;
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
              
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Ejercicios', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Nuevo'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Buscar ejercicio...',
                          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => setState(() => _onlyPopular = !_onlyPopular),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: _onlyPopular ? AppTheme.primaryColor : AppTheme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _onlyPopular ? AppTheme.primaryColor : Colors.white10,
                          ),
                        ),
                        child: Icon(
                          Icons.local_fire_department_outlined,
                          color: _onlyPopular ? Colors.black : AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),

              // FILTROS
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
                        onSelected: (val) => setState(() => _selectedMuscle = m['id']!),
                        backgroundColor: AppTheme.cardColor,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
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
                        onPressed: () => setState(() => _selectedEquipment = eq['id']!),
                        backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : AppTheme.cardColor.withOpacity(0.5),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),
              
              // Sección SCROLLABLE
              Expanded(
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    // POPULARES
                    if (state.popularExercises.isNotEmpty && _searchQuery.isEmpty && !_onlyPopular && _selectedMuscle == 'all' && _selectedEquipment == 'all')
                      SliverToBoxAdapter(
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.local_fire_department_outlined, color: AppTheme.primaryColor, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Más Populares',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () => setState(() => _onlyPopular = true),
                                    child: const Text('Ver todos', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 130, // Aumentado para el GIF
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: state.popularExercises.length,
                                itemBuilder: (context, index) {
                                  final e = state.popularExercises[index];
                                  return GestureDetector(
                                    onTap: () => Navigator.of(context).pop(e),
                                    child: Container(
                                      width: 170, // Un poco más ancho
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardColor,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1), width: 1),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Container(
                                                  width: 40,
                                                  height: 40,
                                                  color: AppTheme.surfaceColor,
                                                  child: e.gifUrl != null && e.gifUrl!.isNotEmpty
                                                      ? Image.network(
                                                          e.gifUrl!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 20),
                                                        )
                                                      : const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 20),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  e.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            translateMuscleGroup(e.muscleGroup),
                                            style: const TextStyle(fontSize: 9, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
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

                    // LISTADO PRINCIPAL
                    if (state.isLoading)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final e = filtered[index];
                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      color: AppTheme.cardColor,
                                      child: e.gifUrl != null && e.gifUrl!.isNotEmpty
                                          ? Image.network(
                                              e.gifUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 24),
                                            )
                                          : const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 24),
                                    ),
                                  ),
                                  title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            translateMuscleGroup(e.muscleGroup),
                                            style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.05),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            translateEquipmentType(e.equipment ?? e.exerciseType),
                                            style: TextStyle(color: AppTheme.hintColor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info_outline, color: Colors.white24, size: 20),
                                        onPressed: () async {
                                          final exercise = await Navigator.of(context).push<Exercise>(
                                            MaterialPageRoute(
                                              builder: (context) => ExerciseDetailScreen(
                                                exercise: e,
                                                showAddButton: true,
                                              ),
                                            ),
                                          );
                                          if (exercise != null && context.mounted) {
                                            Navigator.of(context).pop(exercise);
                                          }
                                        },
                                      ),
                                      const Icon(Icons.add, color: AppTheme.primaryColor, size: 20),
                                    ],
                                  ),
                                  onTap: () => Navigator.of(context).pop(e),
                                ),
                                const Divider(height: 1, color: Colors.white10, indent: 24, endIndent: 24),
                              ],
                            );
                          },
                          childCount: filtered.length,
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
