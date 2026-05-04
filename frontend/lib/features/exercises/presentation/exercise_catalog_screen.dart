import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/exercise_provider.dart';
import 'exercise_detail_screen.dart';
import 'create_exercise_screen.dart';

class ExerciseCatalogScreen extends ConsumerStatefulWidget {
  const ExerciseCatalogScreen({super.key});

  @override
  ConsumerState<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends ConsumerState<ExerciseCatalogScreen> {
  String _searchQuery = '';
  String _selectedMuscle = 'all';
  String _selectedEquipment = 'all';

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
    Future.microtask(() => ref.read(exerciseProvider.notifier).fetchExercises());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(exerciseProvider);
    
    final filtered = state.exercises.where((e) {
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == 'all' || e.muscleGroup == _selectedMuscle;
      final matchesEq = _selectedEquipment == 'all' || e.exerciseType == _selectedEquipment;
      return matchesSearch && matchesMuscle && matchesEq;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Biblioteca', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
              );
            },
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Buscar ejercicio...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                filled: true,
                fillColor: AppTheme.cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          const SizedBox(height: 8),

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
                    labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                    side: BorderSide.none,
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
                    backgroundColor: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.cardColor.withValues(alpha: 0.5),
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
          const Divider(height: 1, color: Colors.white10),

          Expanded(
            child: state.isLoading 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, color: Colors.white10, indent: 24, endIndent: 24),
                  itemBuilder: (context, index) {
                    final e = filtered[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.muscleGroup.toUpperCase(),
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                e.exerciseType.replaceAll('_', ' ').toUpperCase(),
                                style: TextStyle(color: AppTheme.hintColor.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (!e.isGlobal) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MÍO',
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white10, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ExerciseDetailScreen(
                              exercise: e,
                              showAddButton: false,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
