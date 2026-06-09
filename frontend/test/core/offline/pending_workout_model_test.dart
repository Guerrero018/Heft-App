import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/offline/pending_workout_model.dart';

void main() {
  test('PendingWorkout serializes and restores', () {
    final original = PendingWorkout(
      localId: 'local-1',
      payload: {'name': 'Push', 'sets': []},
      createdAt: DateTime.utc(2026, 5, 10, 8),
      retryCount: 2,
    );

    final restored = PendingWorkout.fromJson(original.toJson());
    expect(restored.localId, 'local-1');
    expect(restored.displayName, 'Push');
    expect(restored.retryCount, 2);
    expect(restored.payload['sets'], isEmpty);
  });

  test('displayName falls back when name empty', () {
    final pending = PendingWorkout(payload: {'name': '  '});
    expect(pending.displayName, 'Entrenamiento');
  });

  test('copyWith updates retry count', () {
    final pending = PendingWorkout(payload: {'name': 'A'});
    final next = pending.copyWith(retryCount: 1);
    expect(next.retryCount, 1);
    expect(next.localId, pending.localId);
  });
}
