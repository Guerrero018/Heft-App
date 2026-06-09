import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';

class ExportPreview {
  final int workoutsCount;
  final int bodyMeasuresCount;
  final int prsCount;

  const ExportPreview({
    required this.workoutsCount,
    required this.bodyMeasuresCount,
    required this.prsCount,
  });

  factory ExportPreview.fromJson(Map<String, dynamic> json) {
    return ExportPreview(
      workoutsCount: json['workouts_count'] as int? ?? 0,
      bodyMeasuresCount: json['body_measures_count'] as int? ?? 0,
      prsCount: json['prs_count'] as int? ?? 0,
    );
  }

  int get total => workoutsCount + bodyMeasuresCount + prsCount;
}

class ExportRequest {
  final String format;
  final bool includeWorkouts;
  final bool includeBodyMeasures;
  final bool includePrs;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final int? routineId;
  final int? exerciseId;

  const ExportRequest({
    this.format = 'csv',
    this.includeWorkouts = true,
    this.includeBodyMeasures = true,
    this.includePrs = true,
    this.dateFrom,
    this.dateTo,
    this.routineId,
    this.exerciseId,
  });

  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'include_workouts': includeWorkouts,
      'include_body_measures': includeBodyMeasures,
      'include_prs': includePrs,
      if (dateFrom != null) 'date_from': _formatDate(dateFrom!),
      if (dateTo != null) 'date_to': _formatDate(dateTo!),
      if (routineId != null) 'routine_id': routineId,
      if (exerciseId != null) 'exercise_id': exerciseId,
    };
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class ExportDownloadResult {
  final List<int> bytes;
  final String filename;
  final String mimeType;

  const ExportDownloadResult({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });
}

Future<ExportPreview> fetchExportPreview(
  ExportRequest request, {
  Dio? client,
}) async {
  final dio = client ?? apiClient;
  final response = await dio.post('exports/preview/', data: request.toJson());
  final data = response.data;
  if (data is! Map) {
    throw Exception('Respuesta de vista previa invalida');
  }
  return ExportPreview.fromJson(Map<String, dynamic>.from(data));
}

Future<ExportDownloadResult> downloadExport(
  ExportRequest request, {
  Dio? client,
}) async {
  final dio = client ?? apiClient;
  final response = await dio.post<List<int>>(
    'exports/download/',
    data: request.toJson(),
    options: Options(responseType: ResponseType.bytes),
  );

  final bytes = response.data;
  if (bytes == null || bytes.isEmpty) {
    throw Exception('El archivo exportado esta vacio');
  }

  final disposition = response.headers.value('content-disposition') ?? '';
  final filename = _parseFilename(disposition) ?? _defaultFilename(request.format);
  final contentType = response.headers.value('content-type') ?? 'application/octet-stream';

  return ExportDownloadResult(
    bytes: bytes,
    filename: filename,
    mimeType: contentType,
  );
}

String? _parseFilename(String disposition) {
  final match = RegExp(r'filename="([^"]+)"').firstMatch(disposition);
  return match?.group(1);
}

String _defaultFilename(String format) {
  final stamp = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
  if (format == 'pdf') return 'heft_export_$stamp.pdf';
  return 'heft_export_$stamp.csv';
}
