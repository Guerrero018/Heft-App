import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/offline/connectivity_provider.dart';
import '../../core/offline/offline_sync_provider.dart';
import '../../core/offline/widgets/offline_status_banner.dart';
import '../../core/utils/label_translations.dart';
import '../auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../routines/data/routine_provider.dart';
import '../routines/domain/routine_model.dart';
import '../routines/presentation/create_routine_screen.dart';
import '../routines/presentation/routine_detail_screen.dart';
import '../routines/presentation/routine_template_library_screen.dart';
import '../routines/presentation/widgets/routine_options_sheet.dart';
import '../exercises/presentation/exercise_catalog_screen.dart';
import '../live_workout/domain/live_workout_provider.dart';
import '../live_workout/presentation/screens/live_workout_screen.dart';
import '../statistics/presentation/statistics_screen.dart';
import '../workouts/presentation/screens/workout_history_screen.dart';
import 'data/week_streak_provider.dart';
import 'presentation/widgets/week_streak_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _InicioTab(),
    StatisticsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final liveWorkoutState = ref.watch(liveWorkoutProvider);
    ref.watch(connectivityProvider);
    ref.watch(offlineSyncProvider);

    return Scaffold(
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(child: IndexedStack(index: _currentIndex, children: _pages)),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (liveWorkoutState.isActive) const _MinimizedWorkoutBar(),
          BottomNavigationBar(
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
        onRefresh: () async {
          await ref.read(routineProvider.notifier).fetchRoutines();
          ref.invalidate(weekStreakProvider);
        },
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
                        style: TextStyle(
                          color: AppTheme.hintColor,
                          fontSize: 14,
                        ),
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
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const WorkoutHistoryScreen(),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.history_rounded,
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Historial',
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ExerciseCatalogScreen(),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fitness_center_rounded,
                            color: AppTheme.primaryColor.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                        tooltip: 'Biblioteca de ejercicios',
                      ),
                    ],
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
              const SizedBox(height: 12),
              const WeekStreakCard(),

              // Empezar Entrenamiento Rápido
              _buildActionCard(
                context,
                title: 'Entrenamiento Vacío',
                subtitle: 'Empieza sin una rutina definida',
                icon: Icons.add_rounded,
                onTap: () {
                  ref.read(liveWorkoutProvider.notifier).startWorkout(null);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LiveWorkoutScreen(),
                    ),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 8),

              const SizedBox(height: 32),

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
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Biblioteca de plantillas',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const RoutineTemplateLibraryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.library_books_outlined,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateRoutineScreen(),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (routineState.isLoading && routineState.routines.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  ),
                )
              else if (routineState.routines.isEmpty)
                _buildEmptyState()
              else
                const _RoutinesListSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
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
          color: isPrimary
              ? AppTheme.primaryColor.withOpacity(0.1)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary
                ? AppTheme.primaryColor.withOpacity(0.3)
                : Colors.white.withOpacity(0.05),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppTheme.primaryColor
                    : Colors.white.withOpacity(0.05),
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
                      color: isPrimary
                          ? AppTheme.primaryColor
                          : AppTheme.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppTheme.hintColor, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.hintColor.withOpacity(0.5),
            ),
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
          Icon(
            Icons.fitness_center_rounded,
            size: 48,
            color: AppTheme.hintColor.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes rutinas todavía',
            style: TextStyle(
              color: AppTheme.textColor,
              fontWeight: FontWeight.bold,
            ),
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

class _RoutinesListSection extends ConsumerStatefulWidget {
  const _RoutinesListSection();

  @override
  ConsumerState<_RoutinesListSection> createState() =>
      _RoutinesListSectionState();
}

class _RoutinesListSectionState extends ConsumerState<_RoutinesListSection> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final routineState = ref.watch(routineProvider);
    final active = routineState.activeRoutines;
    final archived = routineState.archivedRoutines;

    return Column(
      children: [
        if (active.isEmpty)
          _buildNoActiveRoutinesMessage(archived.isNotEmpty)
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: active.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return RoutineCard(
                key: ValueKey(active[index].id),
                routine: active[index],
              );
            },
          ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() => _showArchived = !_showArchived),
              icon: Icon(
                _showArchived
                    ? Icons.expand_less
                    : Icons.archive_outlined,
                size: 18,
              ),
              label: Text(
                _showArchived
                    ? 'Ocultar archivadas (${archived.length})'
                    : 'Ver archivadas (${archived.length})',
              ),
            ),
          ),
          if (_showArchived)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: archived.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return Opacity(
                  opacity: 0.75,
                  child: RoutineCard(
                    key: ValueKey('archived-${archived[index].id}'),
                    routine: archived[index],
                  ),
                );
              },
            ),
        ],
      ],
    );
  }

  Widget _buildNoActiveRoutinesMessage(bool hasArchived) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        hasArchived
            ? 'No tienes rutinas activas. Restaura una archivada o crea una nueva.'
            : 'Crea tu primera rutina con el botón +',
        style: const TextStyle(color: AppTheme.hintColor),
      ),
    );
  }
}

class RoutineCard extends ConsumerWidget {
  final Routine routine;

  const RoutineCard({super.key, required this.routine});

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RoutineDetailScreen(routine: routine),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Extraer grupos musculares únicos para mostrar como etiquetas
    final muscleGroups = routine.exercises
        .map((e) => translateMuscleGroup(e.muscleGroup))
        .toSet()
        .toList();

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
            onTap: () => _openDetail(context),
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
                      IconButton(
                        icon: const Icon(
                          Icons.more_vert,
                          color: AppTheme.hintColor,
                          size: 20,
                        ),
                        onPressed: () =>
                            showRoutineOptionsSheet(context, ref, routine),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (muscleGroups.isEmpty)
                    const Text(
                      'Sin ejercicios',
                      style: TextStyle(
                        color: AppTheme.hintColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: muscleGroups.map((muscle) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          muscle.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )).toList(),
                    ),
                  const SizedBox(height: 16),

                  // Resumen de ejercicios
                  if (routine.exercises.isNotEmpty) ...[
                    ...routine.exercises
                        .take(3)
                        .map(
                          (e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 6,
                                  color: AppTheme.hintColor.withOpacity(0.5),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${e.targetSets} x ${e.exerciseName}',
                                    style: TextStyle(
                                      color: AppTheme.textColor.withOpacity(
                                        0.7,
                                      ),
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    if (routine.exercises.length > 3)
                      Text(
                        '+ ${routine.exercises.length - 3} más...',
                        style: const TextStyle(
                          color: AppTheme.hintColor,
                          fontSize: 12,
                        ),
                      ),
                  ],

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(liveWorkoutProvider.notifier)
                          .startWorkout(routine);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LiveWorkoutScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 45),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'EMPEZAR RUTINA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

class _MinimizedWorkoutBar extends ConsumerWidget {
  const _MinimizedWorkoutBar();

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    if (mins > 0) {
      return '${mins}min ${secs}s';
    }
    return '${secs}s';
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          '¿Descartar entrenamiento?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Se perderá todo el progreso de esta sesión.',
          style: TextStyle(color: AppTheme.hintColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Continuar',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(liveWorkoutProvider.notifier).cancelWorkout();
            },
            child: const Text(
              'Descartar',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveWorkoutProvider);
    final lastExercise = state.activeExercises.isNotEmpty
        ? state.activeExercises.last.routineExercise.exerciseName
        : 'Entrenamiento';

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const LiveWorkoutScreen()),
          );
        },
        borderRadius: BorderRadius.circular(40),
        child: Row(
          children: [
            // Expand Button
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.sessionName.isEmpty
                            ? 'Entrenamiento'
                            : state.sessionName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(state.elapsedSeconds),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    lastExercise,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Discard Button
            IconButton(
              onPressed: () => _confirmCancel(context, ref),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
