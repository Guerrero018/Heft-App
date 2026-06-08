import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_message.dart';
import '../achievements/data/achievements_provider.dart';
import '../auth/auth_provider.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Temporary state for onboarding data
  String _gender = 'Masculino';
  double _weight = 75.0;
  double _height = 175.0;
  int _age = 25;
  String _experience = 'Principiante';
  String _goal = 'Ganar Fuerza';
  int _daysPerWeek = 3;
  int _duration = 60;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final data = {
      'gender': _gender,
      'height': _height,
      'weight': _weight,
      'experience_level': _experience,
      'fitness_goal': _goal,
      'workout_days_per_week': _daysPerWeek,
      'workout_duration_minutes': _duration,
    };

    await ref.read(authProvider.notifier).updateProfile(data: data);

    if (!mounted) return;

    final error = ref.read(authProvider).error;
    if (error == null) {
      await ref.read(achievementsProvider.notifier).sync(unlockedBaseline: {});
    }

    if (!mounted) return;

    if (error != null) {
      AppMessage.showError(context, error);
      return;
    }

    AppMessage.showSuccess(context, 'Perfil configurado correctamente');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildBioPage(),
                  _buildExperiencePage(),
                  _buildSchedulePage(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Stack(
        children: [
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 6,
            width: MediaQuery.of(context).size.width * ((_currentPage + 1) / 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text('Atrás', style: TextStyle(color: Colors.white54)),
            )
          else
            const SizedBox(width: 60),
          ElevatedButton(
            onPressed: _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: AppTheme.primaryColor.withOpacity(0.5),
            ),
            child: Text(
              _currentPage == 2 ? 'Comenzar' : 'Siguiente',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBioPage() {
    return ListView(
      children: [
        _buildHeader('Cuéntanos sobre ti', 'Para personalizar tus métricas de fuerza y salud.'),
        const SizedBox(height: 30),
        _buildSectionTitle('Género'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildChoiceCard('Masculino', _gender == 'Masculino', (val) => setState(() => _gender = val)),
              const SizedBox(width: 16),
              _buildChoiceCard('Femenino', _gender == 'Femenino', (val) => setState(() => _gender = val)),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildSectionTitle('Edad: $_age años'),
        Slider(
          value: _age.toDouble(),
          min: 15,
          max: 80,
          activeColor: AppTheme.primaryColor,
          inactiveColor: Colors.white10,
          onChanged: (val) => setState(() => _age = val.toInt()),
        ),
        const SizedBox(height: 30),
        _buildSectionTitle('Peso: ${_weight.toStringAsFixed(1)} kg'),
        Slider(
          value: _weight,
          min: 40,
          max: 150,
          activeColor: AppTheme.primaryColor,
          inactiveColor: Colors.white10,
          onChanged: (val) => setState(() => _weight = val),
        ),
        const SizedBox(height: 30),
        _buildSectionTitle('Altura: ${_height.toInt()} cm'),
        Slider(
          value: _height,
          min: 140,
          max: 220,
          activeColor: AppTheme.primaryColor,
          inactiveColor: Colors.white10,
          onChanged: (val) => setState(() => _height = val),
        ),
      ],
    );
  }

  Widget _buildExperiencePage() {
    return ListView(
      children: [
        _buildHeader('Tu experiencia', 'Esto nos ayudará a elegir la mejor rutina para ti.'),
        const SizedBox(height: 30),
        _buildSectionTitle('Nivel'),
        _buildOptionTile('Principiante', 'Nunca he entrenado o llevo menos de 6 meses.', _experience == 'Principiante'),
        _buildOptionTile('Intermedio', 'Entreno regularmente desde hace 1-2 años.', _experience == 'Intermedio'),
        _buildOptionTile('Avanzado', 'Llevo más de 3 años entrenando en serio.', _experience == 'Avanzado'),
        const SizedBox(height: 30),
        _buildSectionTitle('Tu objetivo principal'),
        _buildGoalTile('Ganar Fuerza', Icons.bolt, _goal == 'Ganar Fuerza'),
        _buildGoalTile('Masa Muscular', Icons.fitness_center, _goal == 'Masa Muscular'),
        _buildGoalTile('Perder Grasa', Icons.shutter_speed, _goal == 'Perder Grasa'),
      ],
    );
  }

  Widget _buildSchedulePage() {
    return ListView(
      children: [
        _buildHeader('Tu disponibilidad', 'Diseñaremos tu plan semanal en base a esto.'),
        const SizedBox(height: 30),
        _buildSectionTitle('Días de entrenamiento por semana'),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(7, (index) {
            int d = index + 1;
            bool isSelected = _daysPerWeek == d;
            return GestureDetector(
              onTap: () => setState(() => _daysPerWeek = d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    d.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 50),
        _buildSectionTitle('Duración por sesión: $_duration min'),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDurationChip(30),
              _buildDurationChip(45),
              _buildDurationChip(60),
              _buildDurationChip(90),
              _buildDurationChip(120),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChoiceCard(String label, bool isSelected, Function(String) onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.white10,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white70,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile(String title, String subtitle, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _experience = title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalTile(String title, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => _goal = title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryColor : Colors.white54, size: 28),
            const SizedBox(width: 20),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(int duration) {
    bool isSelected = _duration == duration;
    return GestureDetector(
      onTap: () => setState(() => _duration = duration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${duration}m',
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
