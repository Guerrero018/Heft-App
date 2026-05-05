import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/workout_provider.dart';
import '../../domain/workout_model.dart';
import 'package:intl/intl.dart';
import 'workout_detail_screen.dart';

class WorkoutHistoryScreen extends ConsumerStatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  ConsumerState<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends ConsumerState<WorkoutHistoryScreen> {
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(workoutHistoryProvider);
    final months = _generateLastMonths(12);

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text(
          'HISTORIAL',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildMonthStrip(months, historyState.workouts),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(workoutHistoryProvider.notifier).fetchWorkouts(),
              color: AppTheme.primaryColor,
              child: _buildBody(context, historyState),
            ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _generateLastMonths(int count) {
    final now = DateTime.now();
    return List.generate(count, (index) {
      return DateTime(now.year, now.month - index, 1);
    });
  }

  Widget _buildMonthStrip(List<DateTime> months, List<WorkoutSession> allWorkouts) {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        reverse: true, // Para que el mes actual esté a la derecha o al principio según prefieras
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: months.length,
        itemBuilder: (context, index) {
          final date = months[index];
          final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month;
          
          // Verificar si hay entrenamientos en este mes para el indicador
          final hasWorkouts = allWorkouts.any((w) => 
            w.date.year == date.year && w.date.month == date.month);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMM', 'es').format(date).toUpperCase(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${date.year}',
                    style: TextStyle(
                      color: isSelected ? Colors.black.withOpacity(0.5) : AppTheme.hintColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (hasWorkouts)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.black : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkoutHistoryState state) {
    if (state.isLoading && state.workouts.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
    }

    final filteredWorkouts = state.workouts.where((w) => 
      w.date.year == _selectedDate.year && w.date.month == _selectedDate.month).toList();

    if (filteredWorkouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined, 
              color: AppTheme.hintColor.withOpacity(0.2), 
              size: 80
            ),
            const SizedBox(height: 24),
            Text(
              'Sin actividad en ${DateFormat('MMMM', 'es').format(_selectedDate)}',
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Es un buen momento para empezar!',
              style: TextStyle(color: AppTheme.hintColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredWorkouts.length,
      itemBuilder: (context, index) {
        return _WorkoutCard(workout: filteredWorkouts[index]);
      },
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final WorkoutSession workout;

  const _WorkoutCard({required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMM', 'es');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkoutDetailScreen(workout: workout),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workout.name.isEmpty ? 'Entrenamiento' : workout.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(workout.date),
                          style: const TextStyle(
                            color: AppTheme.hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      workout.duration,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                children: [
                  _buildMiniStat(Icons.fitness_center_rounded, '${workout.uniqueExercisesCount} ejercicios'),
                  const SizedBox(width: 24),
                  _buildMiniStat(Icons.analytics_outlined, '${workout.totalVolume.toInt()} kg'),
                ],
              ),
              const SizedBox(height: 12),
              // Preview of exercises
              Text(
                _getExercisesPreview(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getExercisesPreview() {
    final names = workout.sets.map((s) => s.exerciseName).toSet().take(3).toList();
    if (names.isEmpty) return 'Sin ejercicios';
    String text = names.join(', ');
    if (workout.uniqueExercisesCount > 3) {
      text += '...';
    }
    return text;
  }

  Widget _buildMiniStat(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.hintColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
        ),
      ],
    );
  }
}
