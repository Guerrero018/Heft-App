import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/exercise_model.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      body: CustomScrollView(
        slivers: [
          // CABECERA CON GIF
          SliverAppBar(
            expandedHeight: 350.0,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.surfaceColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  exercise.externalId != null
                      ? CachedNetworkImage(
                          imageUrl: 'https://exercisedb.p.rapidapi.com/image?exerciseId=${exercise.externalId}&resolution=360&rapidapi-key=${dotenv.env['EXERCISE_DB_KEY'] ?? ''}',
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppTheme.primaryColor.withOpacity(0.2),
                                    AppTheme.surfaceColor,
                                  ],
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.fitness_center_rounded,
                                    size: 64,
                                    color: AppTheme.primaryColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    child: Text(
                                      exercise.name.toUpperCase(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.3),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(color: AppTheme.cardColor),
                  // Degradado
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.surfaceColor.withOpacity(0.8),
                          AppTheme.surfaceColor,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ETIQUETAS
                  Row(
                    children: [
                      _buildTag(exercise.muscleGroup.toUpperCase(), AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      _buildTag((exercise.equipment ?? exercise.exerciseType).replaceAll('_', ' ').toUpperCase(), AppTheme.hintColor),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // DESCRIPCIÓN
                  if (exercise.description.isNotEmpty) ...[
                    const Text(
                      'Sobre este ejercicio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      exercise.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // INSTRUCCIONES
                  const Text(
                    'Instrucciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (exercise.instructions.isEmpty)
                    const Text('No hay instrucciones disponibles.', style: TextStyle(color: AppTheme.hintColor))
                  else
                    ...exercise.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // BOTÓN AÑADIR
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).pop(exercise),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: const Text('AÑADIR A RUTINA', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
