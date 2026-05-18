import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/workout_model.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutSession workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d MMMM yyyy', 'es');
    final timeFormat = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                workout.name.isEmpty ? 'Entrenamiento' : workout.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.2),
                      AppTheme.surfaceColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.fitness_center_rounded,
                    size: 64,
                    color: AppTheme.primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderStat('DURACIÓN', workout.duration),
                      _buildHeaderStat('VOLUMEN', '${workout.totalVolume.toInt()} kg'),
                      _buildHeaderStat('EJERCICIOS', '${workout.uniqueExercisesCount}'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    dateFormat.format(workout.date).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${timeFormat.format(workout.startTime)} - ${workout.endTime != null ? timeFormat.format(workout.endTime!) : '--:--'}',
                    style: const TextStyle(color: AppTheme.hintColor),
                  ),
                  
                  if (workout.notes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'NOTAS',
                      style: TextStyle(
                        color: AppTheme.hintColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        workout.notes,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  const Text(
                    'RESUMEN DE EJERCICIOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          
          // List of exercises
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                // Group sets by exercise
                final exercises = _getGroupedExercises();
                final exerciseName = exercises.keys.elementAt(index);
                final sets = exercises[exerciseName]!;
                
                return _ExerciseDetailCard(
                  exerciseName: exerciseName,
                  sets: sets,
                );
              },
              childCount: _getGroupedExercises().length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Map<String, List<WorkoutSet>> _getGroupedExercises() {
    final Map<String, List<WorkoutSet>> grouped = {};
    for (var s in workout.sets) {
      grouped.putIfAbsent(s.exerciseName, () => []).add(s);
    }
    return grouped;
  }

  Widget _buildHeaderStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.hintColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ExerciseDetailCard extends StatelessWidget {
  final String exerciseName;
  final List<WorkoutSet> sets;

  const _ExerciseDetailCard({
    required this.exerciseName,
    required this.sets,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            exerciseName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // Table header
          Row(
            children: [
              const Expanded(child: Center(child: Text('SERIE', style: TextStyle(color: AppTheme.hintColor, fontSize: 10)))),
              const Expanded(child: Center(child: Text('PESO', style: TextStyle(color: AppTheme.hintColor, fontSize: 10)))),
              const Expanded(child: Center(child: Text('REPET.', style: TextStyle(color: AppTheme.hintColor, fontSize: 10)))),
              if (sets.any((s) => s.rpe != null))
                const Expanded(child: Center(child: Text('RPE', style: TextStyle(color: AppTheme.hintColor, fontSize: 10)))),
            ],
          ),
          const SizedBox(height: 8),
          ...sets.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      '${s.setNumber}', 
                      style: const TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold)
                    ),
                  )
                ),
                Expanded(child: Center(child: Text('${s.weight.toString().replaceAll(RegExp(r'\.0$'), '')} kg', style: const TextStyle(color: Colors.white)))),
                Expanded(child: Center(child: Text('${s.reps}', style: const TextStyle(color: Colors.white)))),
                if (sets.any((set) => set.rpe != null))
                  Expanded(child: Center(child: Text(s.rpe?.toString() ?? '-', style: const TextStyle(color: AppTheme.primaryColor)))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
