import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surfaceColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 90,
          title: const Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
              letterSpacing: -0.5,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor,
                ),
                labelColor: Colors.black,
                unselectedLabelColor: AppTheme.hintColor,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Gráficos'),
                  Tab(text: 'Mapa Muscular'),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _ChartsTab(),
            _MuscleMapTab(),
          ],
        ),
      ),
    );
  }
}

class _ChartsTab extends StatefulWidget {
  const _ChartsTab();

  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  String _selectedPeriod = 'Semana';
  final List<String> _periods = ['Semana', 'Mes', '3 Meses', 'Año', 'Todo'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selector de Periodo
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _periods.map((period) {
                final isSelected = _selectedPeriod == period;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(period),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) setState(() => _selectedPeriod = period);
                    },
                    backgroundColor: AppTheme.cardColor,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.hintColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Progreso por Ejercicio'),
          const SizedBox(height: 16),
          _buildExerciseChart(
            'Press de Banca',
            _getMockSpotsForPeriod(_selectedPeriod, 70),
          ),
          const SizedBox(height: 16),
          _buildExerciseChart(
            'Sentadilla',
            _getMockSpotsForPeriod(_selectedPeriod, 100),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Volumen Semanal'),
          const SizedBox(height: 16),
          const _VolumeBarChart(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<FlSpot> _getMockSpotsForPeriod(String period, double base) {
    // Return different mock data based on period to make it feel alive
    switch (period) {
      case 'Semana':
        return [
          FlSpot(0, base - 5), FlSpot(1, base - 2.5), FlSpot(2, base - 2.5),
          FlSpot(3, base), FlSpot(4, base + 2.5), FlSpot(5, base + 5)
        ];
      case 'Mes':
        return [
          FlSpot(0, base - 10), FlSpot(1, base - 5), FlSpot(2, base - 2),
          FlSpot(3, base), FlSpot(4, base + 5), FlSpot(5, base + 10)
        ];
      case '3 Meses':
        return [
          FlSpot(0, base - 20), FlSpot(1, base - 15), FlSpot(2, base - 8),
          FlSpot(3, base - 2), FlSpot(4, base + 5), FlSpot(5, base + 15)
        ];
      default:
        return [
          FlSpot(0, base - 30), FlSpot(1, base - 20), FlSpot(2, base - 10),
          FlSpot(3, base), FlSpot(4, base + 10), FlSpot(5, base + 25)
        ];
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textColor,
      ),
    );
  }

  Widget _buildExerciseChart(String title, List<FlSpot> spots) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                '+12.5%',
                style: TextStyle(color: Colors.greenAccent, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppTheme.primaryColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleMapTab extends StatelessWidget {
  const _MuscleMapTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Carga',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Basado en el volumen de entrenamiento de los últimos 7 días',
            style: TextStyle(color: AppTheme.hintColor, fontSize: 12),
          ),
          const SizedBox(height: 24),
          const _MuscleMapCard(),
          const SizedBox(height: 32),
          
          // Leyenda
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('Baja', AppTheme.primaryColor.withOpacity(0.2)),
                _buildLegendItem('Media', AppTheme.primaryColor.withOpacity(0.5)),
                _buildLegendItem('Alta', AppTheme.primaryColor),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppTheme.hintColor, fontSize: 12)),
      ],
    );
  }
}

class _MuscleMapCard extends StatelessWidget {
  const _MuscleMapCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          // Simplified Body Silhouette (Front)
          Expanded(
            child: Column(
              children: [
                const Text('Frontal', style: TextStyle(color: AppTheme.hintColor, fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BodyPainter(
                      muscleLoads: {
                        'chest': 0.9,
                        'abs': 0.4,
                        'quads': 0.7,
                        'shoulders': 0.6,
                        'biceps': 0.3,
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const VerticalDivider(color: Colors.white10),
          // Simplified Body Silhouette (Back)
          Expanded(
            child: Column(
              children: [
                const Text('Posterior', style: TextStyle(color: AppTheme.hintColor, fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: CustomPaint(
                    size: Size.infinite,
                    painter: _BodyPainter(
                      isBack: true,
                      muscleLoads: {
                        'back': 0.8,
                        'triceps': 0.4,
                        'glutes': 0.5,
                        'hamstrings': 0.3,
                        'calves': 0.2,
                      },
                    ),
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

class _BodyPainter extends CustomPainter {
  final Map<String, double> muscleLoads;
  final bool isBack;

  _BodyPainter({required this.muscleLoads, this.isBack = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1.0;

    final w = size.width;
    final h = size.height;

    // Draw Silhouette Background
    final silhouettePath = _getSilhouettePath(w, h);
    canvas.drawPath(silhouettePath, Paint()..color = Colors.white.withOpacity(0.03));
    canvas.drawPath(silhouettePath, outlinePaint);

    if (isBack) {
      _drawBackMuscles(canvas, w, h, paint);
    } else {
      _drawFrontMuscles(canvas, w, h, paint);
    }
  }

  Path _getSilhouettePath(double w, double h) {
    final path = Path();
    path.moveTo(w * 0.5, h * 0.05); // Head top
    // Head
    path.addOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.08), width: w * 0.12, height: h * 0.1));
    
    // Neck and Shoulders
    path.moveTo(w * 0.45, h * 0.13);
    path.lineTo(w * 0.3, h * 0.18); // Left shoulder
    path.lineTo(w * 0.25, h * 0.4); // Left arm
    path.lineTo(w * 0.32, h * 0.4); // Inner arm
    path.lineTo(w * 0.35, h * 0.25); // Armpit
    path.lineTo(w * 0.35, h * 0.5); // Waist
    path.lineTo(w * 0.28, h * 0.9); // Left leg outer
    path.lineTo(w * 0.45, h * 0.9); // Left leg inner
    path.lineTo(w * 0.5, h * 0.55); // Crotch
    path.lineTo(w * 0.55, h * 0.9); // Right leg inner
    path.lineTo(w * 0.72, h * 0.9); // Right leg outer
    path.lineTo(w * 0.65, h * 0.5); // Waist
    path.lineTo(w * 0.65, h * 0.25); // Armpit
    path.lineTo(w * 0.68, h * 0.4); // Inner arm
    path.lineTo(w * 0.75, h * 0.4); // Right arm
    path.lineTo(w * 0.7, h * 0.18); // Right shoulder
    path.lineTo(w * 0.55, h * 0.13);
    path.close();
    return path;
  }

  void _drawFrontMuscles(Canvas canvas, double w, double h, Paint paint) {
    // Chest (Pecs)
    _drawPath(canvas, muscleLoads['chest'], paint, Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.36, h * 0.18, w * 0.13, h * 0.08), const Radius.circular(8)))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.51, h * 0.18, w * 0.13, h * 0.08), const Radius.circular(8))));

    // Abs
    _drawPath(canvas, muscleLoads['abs'], paint, Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.42, h * 0.28, w * 0.16, h * 0.15), const Radius.circular(4))));

    // Shoulders (Delts)
    _drawPath(canvas, muscleLoads['shoulders'], paint, Path()
      ..addOval(Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.1, h * 0.08))
      ..addOval(Rect.fromLTWH(w * 0.62, h * 0.16, w * 0.1, h * 0.08)));

    // Biceps
    _drawPath(canvas, muscleLoads['biceps'], paint, Path()
      ..addOval(Rect.fromLTWH(w * 0.26, h * 0.25, w * 0.07, h * 0.12))
      ..addOval(Rect.fromLTWH(w * 0.67, h * 0.25, w * 0.07, h * 0.12)));

    // Quads
    _drawPath(canvas, muscleLoads['quads'], paint, Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.52, w * 0.14, h * 0.2), const Radius.circular(10)))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.53, h * 0.52, w * 0.14, h * 0.2), const Radius.circular(10))));
  }

  void _drawBackMuscles(Canvas canvas, double w, double h, Paint paint) {
    // Back (Lats & Traps)
    _drawPath(canvas, muscleLoads['back'], paint, Path()
      ..moveTo(w * 0.35, h * 0.18)
      ..lineTo(w * 0.65, h * 0.18)
      ..lineTo(w * 0.62, h * 0.4)
      ..lineTo(w * 0.38, h * 0.4)
      ..close());

    // Shoulders
    _drawPath(canvas, muscleLoads['shoulders'], paint, Path()
      ..addOval(Rect.fromLTWH(w * 0.28, h * 0.16, w * 0.1, h * 0.08))
      ..addOval(Rect.fromLTWH(w * 0.62, h * 0.16, w * 0.1, h * 0.08)));

    // Triceps
    _drawPath(canvas, muscleLoads['triceps'], paint, Path()
      ..addOval(Rect.fromLTWH(w * 0.25, h * 0.25, w * 0.07, h * 0.12))
      ..addOval(Rect.fromLTWH(w * 0.68, h * 0.25, w * 0.07, h * 0.12)));

    // Glutes
    _drawPath(canvas, muscleLoads['glutes'], paint, Path()
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.35, h * 0.48, w * 0.3, h * 0.08),
        bottomLeft: const Radius.circular(15),
        bottomRight: const Radius.circular(15),
      )));

    // Hamstrings
    _drawPath(canvas, muscleLoads['hamstrings'], paint, Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.58, w * 0.14, h * 0.18), const Radius.circular(8)))
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.53, h * 0.58, w * 0.14, h * 0.18), const Radius.circular(8))));

    // Calves
    _drawPath(canvas, muscleLoads['calves'], paint, Path()
      ..addOval(Rect.fromLTWH(w * 0.37, h * 0.78, w * 0.08, h * 0.1))
      ..addOval(Rect.fromLTWH(w * 0.55, h * 0.78, w * 0.08, h * 0.1)));
  }

  void _drawPath(Canvas canvas, double? load, Paint paint, Path path) {
    final value = load ?? 0.0;
    if (value > 0) {
      paint.color = AppTheme.primaryColor.withOpacity(0.1 + (value * 0.9));
      canvas.drawPath(path, paint);
      
      // Glow effect for high load
      if (value > 0.7) {
        final glowPaint = Paint()
          ..color = AppTheme.primaryColor.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawPath(path, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _VolumeBarChart extends StatelessWidget {
  const _VolumeBarChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['Pecho', 'Esp.', 'Homb.', 'Pier.', 'Bra.'];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      titles[value.toInt()],
                      style: const TextStyle(color: AppTheme.hintColor, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: [
            _makeGroupData(0, 85),
            _makeGroupData(1, 65),
            _makeGroupData(2, 45),
            _makeGroupData(3, 90),
            _makeGroupData(4, 30),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppTheme.primaryColor,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ],
    );
  }
}
