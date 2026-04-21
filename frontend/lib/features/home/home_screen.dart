import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../routines/data/routine_provider.dart';
import '../routines/domain/routine_model.dart';
import '../routines/presentation/create_routine_screen.dart';
import '../exercises/presentation/exercise_catalog_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _InicioTab(),
    _EstadisticasTab(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            if (index >= 0 && index < _pages.length) {
              _currentIndex = index;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Estadísticas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}



class _InicioTab extends ConsumerWidget {
  const _InicioTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routineState = ref.watch(routineProvider);
    final Color cardBgColor = Theme.of(context).cardColor;

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => ref.read(routineProvider.notifier).fetchRoutines(),
        color: AppTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con Saludo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Hola de nuevo, ',
                        style: TextStyle(color: AppTheme.hintColor, fontSize: 14),
                      ),
                      Text(
                        ref.watch(authProvider).user?['username'] ?? '',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ExerciseCatalogScreen()),
                      );
                    },
                    icon: Icon(Icons.fitness_center_rounded, color: AppTheme.hintColor.withOpacity(0.4), size: 20),
                    tooltip: 'Biblioteca de ejercicios',
                  ),
                ],
              ),
              const Text(
                'Entrenamiento',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Empezar Entrenamiento Rápido
              _buildActionCard(
                context,
                title: 'Entrenamiento Vacío',
                subtitle: 'Empieza sin una rutina definida',
                icon: Icons.add_rounded,
                onTap: () {},
                isPrimary: true,
              ),
              const SizedBox(height: 40),

              // Sección de Rutinas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tus Rutinas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textColor,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (routineState.isLoading && routineState.routines.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              else if (routineState.routines.isEmpty)
                _buildEmptyState()
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routineState.routines.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    return RoutineCard(routine: routineState.routines[index]);
                  },
                ),
                
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? AppTheme.primaryColor.withOpacity(0.1) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.black : AppTheme.textColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isPrimary ? AppTheme.primaryColor : AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.hintColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.hintColor.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.fitness_center_rounded, size: 48, color: AppTheme.hintColor.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text(
            'No tienes rutinas todavía',
            style: TextStyle(color: AppTheme.textColor, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Crea tu primera rutina para empezar a entrenar de forma inteligente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.hintColor, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class RoutineCard extends ConsumerWidget {
  final Routine routine;

  const RoutineCard({super.key, required this.routine});

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Eliminar Rutina', style: TextStyle(color: Colors.white)),
        content: Text('¿Estás seguro de que deseas eliminar la rutina "${routine.name}"?',
            style: const TextStyle(color: AppTheme.hintColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.hintColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(routineProvider.notifier).deleteRoutine(routine.id!);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extraer grupos musculares únicos para el subtitulo
    final muscleGroups = routine.exercises
        .map((e) => _translateMuscle(e.muscleGroup))
        .toSet()
        .join(', ');

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          routine.name,
                          style: const TextStyle(
                            color: AppTheme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.hintColor, size: 20),
                        color: AppTheme.cardColor,
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CreateRoutineScreen(existingRoutine: routine),
                              ),
                            );
                          } else if (value == 'delete') {
                            _confirmDelete(context, ref);
                          }
                        },
                        itemBuilder: (BuildContext context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: AppTheme.textColor, size: 18),
                                SizedBox(width: 8),
                                Text('Editar', style: TextStyle(color: AppTheme.textColor)),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.redAccent, size: 18),
                                SizedBox(width: 8),
                                Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    muscleGroups.isEmpty ? 'Sin ejercicios' : muscleGroups,
                    style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  
                  // Resumen de ejercicios
                  if (routine.exercises.isNotEmpty) ...[
                    ...routine.exercises.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: AppTheme.hintColor.withOpacity(0.5)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.targetSets} x ${e.exerciseName}',
                              style: TextStyle(color: AppTheme.textColor.withOpacity(0.7), fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    )),
                    if (routine.exercises.length > 3)
                      Text(
                        '+ ${routine.exercises.length - 3} más...',
                        style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
                      ),
                  ],

                  
                  const SizedBox(height: 20),
                  
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('EMPEZAR RUTINA', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _translateMuscle(String muscle) {
    const translations = {
      'chest': 'Pecho',
      'back': 'Espalda',
      'shoulders': 'Hombros',
      'biceps': 'Bíceps',
      'triceps': 'Tríceps',
      'quadriceps': 'Cuádriceps',
      'hamstrings': 'Isquios',
      'glutes': 'Glúteos',
      'calves': 'Gemelos',
      'abs': 'Abs',
    };
    return translations[muscle.toLowerCase()] ?? muscle;
  }
}

class _EstadisticasTab extends StatelessWidget {
  const _EstadisticasTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Estadísticas',
        style: TextStyle(color: AppTheme.textColor, fontSize: 24),
      ),
    );
  }
}


