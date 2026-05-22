import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/body_measure_model.dart';

/// Comparación lado a lado de dos fotos de progreso.
class PhotoCompareScreen extends StatefulWidget {
  final BodyMeasureEntry before;
  final BodyMeasureEntry after;

  const PhotoCompareScreen({
    super.key,
    required this.before,
    required this.after,
  });

  @override
  State<PhotoCompareScreen> createState() => _PhotoCompareScreenState();
}

class _PhotoCompareScreenState extends State<PhotoCompareScreen> {
  double _sliderPosition = 0.5;
  bool _useSlider = true;

  BodyMeasureEntry get _older =>
      widget.before.date.isBefore(widget.after.date) ? widget.before : widget.after;

  BodyMeasureEntry get _newer =>
      widget.before.date.isBefore(widget.after.date) ? widget.after : widget.before;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Comparar fotos',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: _useSlider ? 'Vista dividida' : 'Deslizador',
            onPressed: () => setState(() => _useSlider = !_useSlider),
            icon: Icon(
              _useSlider ? Icons.view_column_outlined : Icons.compare,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(child: _DateLabel(entry: _older, tag: 'Antes')),
                const Icon(Icons.arrow_forward, color: AppTheme.hintColor, size: 18),
                Expanded(child: _DateLabel(entry: _newer, tag: 'Después')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _useSlider ? _buildSliderCompare() : _buildSideBySide(),
            ),
          ),
          _WeightDeltaBar(before: _older, after: _newer),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSideBySide() {
    return Row(
      children: [
        Expanded(child: _PhotoPanel(entry: _older)),
        const SizedBox(width: 8),
        Expanded(child: _PhotoPanel(entry: _newer)),
      ],
    );
  }

  Widget _buildSliderCompare() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final splitX = w * _sliderPosition;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _PhotoImage(url: _newer.photoUrl ?? '', fit: BoxFit.cover),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: splitX,
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: SizedBox(
                      width: w,
                      height: h,
                      child: _PhotoImage(url: _older.photoUrl ?? '', fit: BoxFit.cover),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: splitX - 1,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  color: AppTheme.primaryColor,
                ),
              ),
              Positioned(
                left: splitX - 20,
                top: h / 2 - 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_horiz, color: Colors.black),
                ),
              ),
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (d) {
                    setState(() {
                      _sliderPosition = (_sliderPosition + d.delta.dx / w).clamp(0.05, 0.95);
                    });
                  },
                  onTapDown: (d) {
                    setState(() {
                      _sliderPosition = (d.localPosition.dx / w).clamp(0.05, 0.95);
                    });
                  },
                  behavior: HitTestBehavior.translucent,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PhotoPanel extends StatelessWidget {
  final BodyMeasureEntry entry;

  const _PhotoPanel({required this.entry});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _PhotoImage(url: entry.photoUrl ?? '', fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                '${entry.weight.toStringAsFixed(1)} kg',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const _PhotoImage({required this.url, required this.fit});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 3,
      child: CachedNetworkImage(imageUrl: url, fit: fit, width: double.infinity, height: double.infinity),
    );
  }
}

class _DateLabel extends StatelessWidget {
  final BodyMeasureEntry entry;
  final String tag;

  const _DateLabel({required this.entry, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(tag, style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(
          DateFormat('d MMM yyyy', 'es').format(entry.date),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}

class _WeightDeltaBar extends StatelessWidget {
  final BodyMeasureEntry before;
  final BodyMeasureEntry after;

  const _WeightDeltaBar({required this.before, required this.after});

  @override
  Widget build(BuildContext context) {
    final delta = after.weight - before.weight;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${before.weight.toStringAsFixed(1)} kg',
            style: const TextStyle(color: AppTheme.hintColor),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward, color: AppTheme.hintColor, size: 16),
          ),
          Text(
            '${after.weight.toStringAsFixed(1)} kg',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            '(${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(1)} kg)',
            style: TextStyle(
              color: delta <= 0 ? Colors.lightGreenAccent : Colors.orangeAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
