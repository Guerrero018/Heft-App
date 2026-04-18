import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/routine_provider.dart';
import '../../exercises/data/exercise_provider.dart';
import '../../exercises/domain/exercise_model.dart';

class CreateRoutineScreen extends ConsumerStatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  ConsumerState<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends ConsumerState<CreateRoutineScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<SelectedExercise> _selectedExercises = [];

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
      // Usamos el provider para crear la rutina
      // Nota: Necesitaremos un método en el provider que acepte ejercicios
       await ref.read(routineProvider.notifier).createRoutineWithExercises(
        name,
        _descriptionController.text.trim(),
        exercisesData,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rutina creada con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear rutina: $e')),
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
        title: const Text('Nueva Rutina', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildInputColumn('Reps', (val) => item.reps = int.tryParse(val) ?? 0, item.reps.toString()),
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

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(exerciseProvider.notifier).fetchExercises());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);
    final filtered = state.exercises.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Seleccionar Ejercicio', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Buscar ejercicio...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: state.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final e = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(e.muscleGroup.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                        onTap: () => Navigator.of(context).pop(e),
                      );
                    },
                  ),
            ),
          ],
        );
      },
    );
  }
}
