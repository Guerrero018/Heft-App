import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../domain/statistics_model.dart';

/// Carga estadísticas agregadas desde el backend.
Future<UserStatistics?> fetchUserStatisticsFromApi(
  String period, {
  Dio? client,
}) async {
  final dio = client ?? apiClient;
  try {
    final response = await dio.get(
      'statistics/',
      queryParameters: {'period': period},
    );
    final data = response.data;
    if (data is! Map) return null;
    return UserStatistics.fromJson(Map<String, dynamic>.from(data));
  } catch (e, stack) {
    debugPrint('Statistics API error ($period): $e\n$stack');
    return null;
  }
}
