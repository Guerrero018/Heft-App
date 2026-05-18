import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'muscle_fatigue_colors.dart';

/// Ilustración anatómica (SVG Ryan Graves / flutter-body-atlas, CC BY 4.0).
/// Vista frontal y posterior; colorea músculos según fatiga semanal.
class AnatomySilhouetteView extends StatelessWidget {
  final double width;
  final Map<String, double> frontLoads;
  final Map<String, double> backLoads;

  const AnatomySilhouetteView({
    super.key,
    required this.width,
    this.frontLoads = const {},
    this.backLoads = const {},
  });

  static const _frontAsset = 'assets/muscle_map/muscle_layer_front.svg';
  static const _backAsset = 'assets/muscle_map/muscle_layer_back.svg';

  @override
  Widget build(BuildContext context) {
    final gap = width * 0.04;
    final padH = width * 0.06;
    final bodyW = (width - gap - padH * 2) / 2;
    const frontAspect = 587 / 1137;
    const backAspect = 596 / 1133;
    final frontH = bodyW / frontAspect;
    final backH = bodyW / backAspect;
    final mapHeight = frontH > backH ? frontH : backH;

    return Container(
      color: const Color(0xFF141414),
      height: mapHeight + 36,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _Figure(
                      asset: _frontAsset,
                      title: 'FRONTAL',
                      height: frontH,
                      colorMapper: MuscleFatigueColorMapper(
                        loads: frontLoads,
                        isFront: true,
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    child: _Figure(
                      asset: _backAsset,
                      title: 'POSTERIOR',
                      height: backH,
                      colorMapper: MuscleFatigueColorMapper(
                        loads: backLoads,
                        isFront: false,
                      ),
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

class _Figure extends StatelessWidget {
  final String asset;
  final String title;
  final double height;
  final MuscleFatigueColorMapper colorMapper;

  const _Figure({
    required this.asset,
    required this.title,
    required this.height,
    required this.colorMapper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: SvgPicture.asset(
            asset,
            fit: BoxFit.contain,
            alignment: Alignment.bottomCenter,
            colorMapper: colorMapper,
            placeholderBuilder: (_) => const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
