import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Workout finished locally, waiting to sync with the server.
class PendingWorkout {
  final String localId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;

  PendingWorkout({
    String? localId,
    required this.payload,
    DateTime? createdAt,
    this.retryCount = 0,
  })  : localId = localId ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  String get displayName =>
      (payload['name'] as String?)?.trim().isNotEmpty == true
          ? payload['name'] as String
          : 'Entrenamiento';

  Map<String, dynamic> toJson() => {
        'local_id': localId,
        'payload': payload,
        'created_at': createdAt.toUtc().toIso8601String(),
        'retry_count': retryCount,
      };

  factory PendingWorkout.fromJson(Map<String, dynamic> json) {
    return PendingWorkout(
      localId: json['local_id'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      retryCount: json['retry_count'] as int? ?? 0,
    );
  }

  PendingWorkout copyWith({
    int? retryCount,
  }) {
    return PendingWorkout(
      localId: localId,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}
