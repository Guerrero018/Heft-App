import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/exercise_provider.dart';
import 'exercise_detail_screen.dart';
import 'create_exercise_screen.dart';

class ExerciseCatalogScreen extends ConsumerStatefulWidget {
  final bool isSelectionMode;
  const ExerciseCatalogScreen({super.key, this.isSelectionMode = false});

  @override
  ConsumerState<ExerciseCatalogScreen> createState() => _ExerciseCatalogScreenState();
}

class _ExerciseCatalogScreenState extends ConsumerState<ExerciseCatalogScreen> {
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
      // Filtros
      final matchesSearch = e.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesMuscle = _selectedMuscle == 'all' || e.muscleGroup == _selectedMuscle;
      final matchesEq = _selectedEquipment == 'all' || e.exerciseType == _selectedEquipment;
      
      return matchesSearch && matchesMuscle && matchesEq;
    }).toList();

    // print("Populares: ${state.popularExercises.length}, Search: '${_searchQuery}', Muscle: '${_selectedMuscle}'");

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
          // Sección FIJA: Buscador y Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Expanded(
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
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_outlined,
                          color: _onlyPopular ? Colors.black : AppTheme.primaryColor,
                          size: 20,
                        ),
                        if (_onlyPopular) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'POPULAR',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
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

          const SizedBox(height: 8),
          
          const Divider(height: 1, color: Colors.white10),

          // Sección SCROLLABLE
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Carrusel de populares (Solo se muestra si cumple las condiciones)
                if (state.popularExercises.isNotEmpty && _searchQuery.isEmpty && !_onlyPopular && _selectedMuscle == 'all' && _selectedEquipment == 'all')
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: state.popularExercises.length,
                            itemBuilder: (context, index) {
                              final e = state.popularExercises[index];
                              return GestureDetector(
                                onTap: () {
                                  if (widget.isSelectionMode) {
                                    Navigator.of(context).pop(e);
                                  } else {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseDetailScreen(
                                          exercise: e,
                                          showAddButton: false,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 160,
                                  margin: const EdgeInsets.only(right: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          e.muscleGroup.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(height: 1, color: Colors.white10),
                      ],
                    ),
                  ),

                // Listado principal
                if (state.isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
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
                                if (widget.isSelectionMode) {
                                  Navigator.of(context).pop(e);
                                } else {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ExerciseDetailScreen(
                                        exercise: e,
                                        showAddButton: false,
                                      ),
                                    ),
                                  );
                                }
                              },
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
  }
}
