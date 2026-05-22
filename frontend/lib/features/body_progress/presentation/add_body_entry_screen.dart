import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_message.dart';
import '../../auth/auth_provider.dart';
import '../data/body_progress_provider.dart';
import '../domain/body_measure_model.dart';

class AddBodyEntryScreen extends ConsumerStatefulWidget {
  const AddBodyEntryScreen({super.key});

  @override
  ConsumerState<AddBodyEntryScreen> createState() => _AddBodyEntryScreenState();
}

class _AddBodyEntryScreenState extends ConsumerState<AddBodyEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  final _neckController = TextEditingController();
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _bicepLeftController = TextEditingController();
  final _bicepRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _picker = ImagePicker();

  DateTime _selectedDate = DateTime.now();
  final List<File> _imageFiles = [];
  bool _showMeasurements = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    final currentWeight = user?['weight'];
    if (currentWeight != null) {
      _weightController.text =
          double.parse(currentWeight.toString()).toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    _neckController.dispose();
    _chestController.dispose();
    _waistController.dispose();
    _hipsController.dispose();
    _shouldersController.dispose();
    _bicepLeftController.dispose();
    _bicepRightController.dispose();
    _thighLeftController.dispose();
    _thighRightController.dispose();
    super.dispose();
  }

  double? _parseOptional(String value) {
    if (value.trim().isEmpty) return null;
    return double.tryParse(value.replaceAll(',', '.'));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              surface: AppTheme.cardColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_imageFiles.length >= kMaxBodyEntryPhotos) {
      if (!mounted) return;
      AppMessage.showError(
        context,
        'Máximo $kMaxBodyEntryPhotos fotos por registro.',
      );
      return;
    }
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1600,
      imageQuality: 80,
    );
    if (file != null) {
      setState(() => _imageFiles.add(File(file.path)));
    }
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Galería', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              title: const Text('Cámara', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightController.text.replaceAll(',', '.'));
    final ok = await ref.read(bodyProgressProvider.notifier).createEntry(
          weight: weight,
          date: _selectedDate,
          notes: _notesController.text.trim(),
          imagePaths: _imageFiles.map((f) => f.path).toList(),
          neckCm: _parseOptional(_neckController.text),
          chestCm: _parseOptional(_chestController.text),
          waistCm: _parseOptional(_waistController.text),
          hipsCm: _parseOptional(_hipsController.text),
          shouldersCm: _parseOptional(_shouldersController.text),
          bicepLeftCm: _parseOptional(_bicepLeftController.text),
          bicepRightCm: _parseOptional(_bicepRightController.text),
          thighLeftCm: _parseOptional(_thighLeftController.text),
          thighRightCm: _parseOptional(_thighRightController.text),
        );

    if (!mounted) return;

    if (ok) {
      await ref.read(authProvider.notifier).syncProfile();
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    final error = ref.read(bodyProgressProvider).error;
    if (error != null) {
      AppMessage.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(bodyProgressProvider).isLoading;

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Nuevo registro',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha', style: TextStyle(color: AppTheme.hintColor)),
              subtitle: Text(
                DateFormat('d MMM yyyy', 'es').format(_selectedDate),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: IconButton(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Peso (kg)', Icons.monitor_weight_outlined),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (n == null || n <= 0 || n > 500) {
                  return 'Introduce un peso válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Notas (opcional)', Icons.notes_outlined),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _imageFiles.length >= kMaxBodyEntryPhotos
                        ? null
                        : _showImageOptions,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _imageFiles.isEmpty
                          ? 'Añadir fotos (máx. $kMaxBodyEntryPhotos)'
                          : 'Añadir otra foto (${_imageFiles.length}/$kMaxBodyEntryPhotos)',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imageFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final file = _imageFiles[index];
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            file,
                            width: 96,
                            height: 108,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black87,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(28, 28),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => _removeImage(index),
                            icon: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir medidas corporales',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
              ),
              value: _showMeasurements,
              activeThumbColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _showMeasurements = v),
            ),
            if (_showMeasurements) ...[
              _measureField(_neckController, 'Cuello (cm)'),
              _measureField(_chestController, 'Pecho (cm)'),
              _measureField(_waistController, 'Cintura (cm)'),
              _measureField(_hipsController, 'Cadera (cm)'),
              _measureField(_shouldersController, 'Hombros (cm)'),
              _measureField(_bicepLeftController, 'Brazo izquierdo (cm)'),
              _measureField(_bicepRightController, 'Brazo derecho (cm)'),
              _measureField(_thighLeftController, 'Muslo izquierdo (cm)'),
              _measureField(_thighRightController, 'Muslo derecho (cm)'),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('Guardar registro', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _measureField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(color: Colors.white),
        decoration: _inputDecoration(label, Icons.straighten),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.hintColor),
      prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      filled: true,
      fillColor: AppTheme.cardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }
}
