import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/exercise_provider.dart';

class CreateExerciseScreen extends ConsumerStatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  ConsumerState<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends ConsumerState<CreateExerciseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _gifController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedMuscle = 'pecho';
  String _selectedEquipment = 'mancuernas';

  final List<Map<String, String>> _muscleGroups = [
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
    {'id': 'barra', 'name': 'Barra'},
    {'id': 'mancuernas', 'name': 'Mancuernas'},
    {'id': 'maquina', 'name': 'Máquina'},
    {'id': 'polea', 'name': 'Polea'},
    {'id': 'peso_corporal', 'name': 'Peso Corporal'},
    {'id': 'pesa_rusa', 'name': 'Pesa Rusa'},
    {'id': 'maquina_smith', 'name': 'Máquina Smith'},
    {'id': 'otro', 'name': 'Otro'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _gifController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Procesar instrucciones (una por línea)
    final lines = _instructionsController.text
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();

    try {
      await ref.read(exerciseProvider.notifier).createCustomExercise(
        name: _nameController.text.trim(),
        muscleGroup: _selectedMuscle,
        exerciseType: _selectedEquipment,
        description: _descriptionController.text.trim(),
        instructions: lines,
        gifUrl: _gifController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ejercicio creado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al crear ejercicio: $e')),
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
        title: const Text('Crear Ejercicio', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Nombre del ejercicio *'),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Ej: Press Militar con Mancuernas'),
                validator: (v) => v == null || v.isEmpty ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Grupo muscular *'),
                        DropdownButtonFormField<String>(
                          value: _selectedMuscle,
                          items: _muscleGroups.map((m) => DropdownMenuItem(
                            value: m['id'],
                            child: Text(m['name']!),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedMuscle = v!),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Equipamiento *'),
                        DropdownButtonFormField<String>(
                          value: _selectedEquipment,
                          items: _equipmentTypes.map((e) => DropdownMenuItem(
                            value: e['id'],
                            child: Text(e['name']!),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedEquipment = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Descripción'),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Breve explicación de para qué sirve...'),
              ),
              const SizedBox(height: 24),

              _buildLabel('Instrucciones (una por línea)'),
              TextFormField(
                controller: _instructionsController,
                maxLines: 5,
                decoration: const InputDecoration(hintText: 'Paso 1: Agarra las pesas...\nPaso 2: Sube lentamente...'),
              ),
              const SizedBox(height: 24),

              _buildLabel('URL del GIF (opcional)'),
              TextFormField(
                controller: _gifController,
                decoration: const InputDecoration(hintText: 'https://ejemplo.com/ejercicio.gif'),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('GUARDAR EJERCICIO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(color: AppTheme.hintColor, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
