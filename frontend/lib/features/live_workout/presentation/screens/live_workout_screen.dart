import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/auth_provider.dart';
import '../../domain/live_workout_provider.dart';
import '../../domain/live_workout_state.dart';

class LiveWorkoutScreen extends ConsumerWidget {
  const LiveWorkoutScreen({super.key});

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _showSettings(BuildContext context, WidgetRef ref) {
    final state = ref.read(liveWorkoutProvider);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configuraciones de Sesión',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.hintColor),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Temporizador de Descanso', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              subtitle: const Text('Inicia automáticamente el descanso al completar una serie', style: TextStyle(color: AppTheme.hintColor)),
              value: state.enableRestTimer,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                ref.read(liveWorkoutProvider.notifier).setRestTimerEnabled(val);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Cancelar Entrenamiento', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro? Se perderá todo el progreso de la sesión actual.',
            style: TextStyle(color: AppTheme.hintColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Seguir Entrenando', style: TextStyle(color: AppTheme.primaryColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(liveWorkoutProvider.notifier).cancelWorkout();
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(liveWorkoutProvider);
    final user = ref.watch(authProvider).user;
    final trackRpe = user != null && user['track_rpe'] == true;

    return WillPopScope(
      onWillPop: () async {
        _confirmCancel(context, ref);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.surfaceColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
            onPressed: () => _confirmCancel(context, ref),
          ),
          title: Column(
            children: [
              Text(
                state.sessionName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTime(state.elapsedSeconds),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: AppTheme.hintColor),
              onPressed: () => _showSettings(context, ref),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(liveWorkoutProvider.notifier).finishWorkout();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('TERMINAR', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        body: Stack(
          children: [
            if (state.isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            else if (state.activeExercises.isEmpty)
              _buildEmptyState(context)
            else
              ListView.builder(
                padding: const EdgeInsets.only(bottom: 120, top: 16),
                itemCount: state.activeExercises.length,
                itemBuilder: (context, index) {
                  return _ActiveExerciseCard(
                    exerciseIndex: index,
                    exercise: state.activeExercises[index],
                    trackRpe: trackRpe,
                  );
                },
              ),

             // Rest Timer Panel
            if (state.isResting)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _RestTimerPanel(restSeconds: state.restSecondsRemaining),
              ),
          ],
        ),
        floatingActionButton: state.isResting ? null : FloatingActionButton.extended(
          onPressed: () {
            // TODO: Open dialog to add more exercises dynamically
          },
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Añadir Ejercicio', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: AppTheme.hintColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Entrenamiento Vacío',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Añade un ejercicio para empezar a entrenar.',
            style: TextStyle(color: AppTheme.hintColor),
          ),
        ],
      ),
    );
  }
}

class _ActiveExerciseCard extends ConsumerWidget {
  final int exerciseIndex;
  final ActiveExercise exercise;
  final bool trackRpe;

  const _ActiveExerciseCard({
    required this.exerciseIndex,
    required this.exercise,
    required this.trackRpe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del Ejercicio
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise.routineExercise.exerciseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppTheme.hintColor),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Cabeceras de tabla
          Row(
            children: [
              const SizedBox(width: 40, child: Text('Set', style: TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 80, child: Text('Anterior', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold))),
              const Spacer(),
              const SizedBox(width: 60, child: Text('kg', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 60, child: Text('Reps', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold))),
              if (trackRpe)
                const SizedBox(width: 60, child: Text('RPE', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.hintColor, fontWeight: FontWeight.bold))),
              const SizedBox(width: 50, child: Icon(Icons.check, size: 20, color: AppTheme.hintColor)),
            ],
          ),
          const SizedBox(height: 8),

          // Lista de Series
          for (int i = 0; i < exercise.sets.length; i++)
            _SetRow(
              exerciseIndex: exerciseIndex,
              setIndex: i,
              setData: exercise.sets[i],
              trackRpe: trackRpe,
            ),

          const SizedBox(height: 16),
          
          // Botones Serie
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(liveWorkoutProvider.notifier).addSet(exerciseIndex);
                },
                icon: const Icon(Icons.add, color: AppTheme.hintColor),
                label: const Text('Añadir Serie', style: TextStyle(color: AppTheme.hintColor)),
              ),
              if (exercise.sets.length > 1) ...[
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () {
                    ref.read(liveWorkoutProvider.notifier).removeLastSet(exerciseIndex);
                  },
                  icon: const Icon(Icons.remove, color: Colors.redAccent),
                  label: const Text('Quitar Serie', style: TextStyle(color: Colors.redAccent)),
                ),
              ],
            ],
          )
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerWidget {
  final int exerciseIndex;
  final int setIndex;
  final WorkoutSetData setData;
  final bool trackRpe;

  const _SetRow({
    required this.exerciseIndex,
    required this.setIndex,
    required this.setData,
    required this.trackRpe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCompleted = setData.isCompleted;
    final rowColor = isCompleted ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent;

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Type & Number
          SizedBox(
            width: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: _getTypeColor(setData.type).withOpacity(isCompleted ? 1 : 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  _getTypeLetter(setData.type, setIndex + 1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.black : _getTypeColor(setData.type),
                  ),
                ),
              ),
            ),
          ),
          
          // Previous Value
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                setData.prevWeight != null 
                  ? '${setData.prevWeight.toString().replaceAll(RegExp(r'\.0$'), '')}kg x ${setData.prevReps}' 
                  : '-',
                style: const TextStyle(color: AppTheme.hintColor, fontSize: 12),
              ),
            ),
          ),

          const Spacer(),
          
          // Weight Input
          SizedBox(
            width: 60,
            child: _buildInput(
              value: setData.wasModifiedWeight ? setData.weight.toString().replaceAll(RegExp(r'\.0$'), '') : '',
              hint: setData.prevWeight != null 
                ? setData.prevWeight.toString().replaceAll(RegExp(r'\.0$'), '') 
                : (setData.weight > 0 ? setData.weight.toString().replaceAll(RegExp(r'\.0$'), '') : '0'),
              isCompleted: isCompleted,
              isModified: setData.wasModifiedWeight,
              onChanged: (val) {
                final weight = double.tryParse(val);
                if (weight != null) {
                  ref.read(liveWorkoutProvider.notifier).updateSet(exerciseIndex, setData.id, weight: weight);
                }
              },
            ),
          ),
          
          // Reps Input
          SizedBox(
            width: 60,
            child: _buildInput(
              value: setData.wasModifiedReps ? setData.reps.toString() : '',
              hint: setData.prevReps != null 
                ? setData.prevReps.toString() 
                : (setData.reps > 0 ? setData.reps.toString() : '0'),
              isCompleted: isCompleted,
              isModified: setData.wasModifiedReps,
              onChanged: (val) {
                final reps = int.tryParse(val);
                if (reps != null) {
                  ref.read(liveWorkoutProvider.notifier).updateSet(exerciseIndex, setData.id, reps: reps);
                }
              },
            ),
          ),

          // RPE Input
          if (trackRpe)
            SizedBox(
              width: 60,
              child: _buildInput(
                value: setData.rpe?.toString() ?? '',
                 hint: '-',
                isCompleted: isCompleted,
                isModified: setData.wasModifiedRpe,
                onChanged: (val) {
                  final rpe = double.tryParse(val);
                  ref.read(liveWorkoutProvider.notifier).updateSet(exerciseIndex, setData.id, rpe: rpe);
                },
              ),
            ),

          // Complete Toggle
          SizedBox(
            width: 50,
            child: IconButton(
              icon: Icon(
                Icons.check_circle,
                color: isCompleted ? AppTheme.primaryColor : AppTheme.hintColor.withOpacity(0.3),
                size: 28,
              ),
              onPressed: () {
                ref.read(liveWorkoutProvider.notifier).toggleSetComplete(exerciseIndex, setData.id);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String value, 
    String hint = '0', 
    required bool isCompleted, 
    bool isModified = true,
    required Function(String) onChanged
  }) {
    Color textColor;
    if (isCompleted) {
      textColor = AppTheme.primaryColor;
    } else if (isModified) {
      textColor = AppTheme.textColor; // White
    } else {
      textColor = AppTheme.hintColor; // Gray
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.transparent : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontWeight: isCompleted || isModified ? FontWeight.bold : FontWeight.normal,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppTheme.hintColor.withOpacity(0.3),
            fontWeight: FontWeight.normal,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: onChanged,
      ),
    );
  }

  String _getTypeLetter(String type, int index) {
    switch (type) {
      case 'warmup': return 'W';
      case 'dropset': return 'D';
      case 'failure': return 'F';
      default: return '$index';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'warmup': return Colors.orange;
      case 'dropset': return Colors.blue;
      case 'failure': return Colors.red;
      default: return AppTheme.hintColor;
    }
  }
}

class _RestTimerPanel extends ConsumerWidget {
  final int restSeconds;

  const _RestTimerPanel({required this.restSeconds});

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.black, size: 28),
            const SizedBox(width: 12),
            Text(
              _formatTime(restSeconds),
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => ref.read(liveWorkoutProvider.notifier).adjustRestTimer(-10),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: const Text('-10s'),
            ),
            TextButton(
              onPressed: () => ref.read(liveWorkoutProvider.notifier).adjustRestTimer(30),
              style: TextButton.styleFrom(foregroundColor: Colors.black54),
              child: const Text('+30s'),
            ),
            IconButton(
              onPressed: () => ref.read(liveWorkoutProvider.notifier).stopRestTimer(),
              icon: const Icon(Icons.close, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}
