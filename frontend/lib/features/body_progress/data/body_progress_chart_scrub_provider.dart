import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bloquea el swipe del TabBarView mientras se arrastra sobre un gráfico.
class BodyProgressChartScrubNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setActive(bool active) => state = active;
}

final bodyProgressChartScrubProvider =
    NotifierProvider<BodyProgressChartScrubNotifier, bool>(
  BodyProgressChartScrubNotifier.new,
);
