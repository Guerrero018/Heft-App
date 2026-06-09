import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api/api_client.dart';
import 'export_api_service.dart';

class ExportState {
  final ExportRequest request;
  final ExportPreview? preview;
  final bool isPreviewLoading;
  final bool isExporting;
  final String? error;

  const ExportState({
    this.request = const ExportRequest(),
    this.preview,
    this.isPreviewLoading = false,
    this.isExporting = false,
    this.error,
  });

  ExportState copyWith({
    ExportRequest? request,
    ExportPreview? preview,
    bool? isPreviewLoading,
    bool? isExporting,
    String? error,
    bool clearError = false,
    bool clearPreview = false,
  }) {
    return ExportState(
      request: request ?? this.request,
      preview: clearPreview ? null : (preview ?? this.preview),
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      isExporting: isExporting ?? this.isExporting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() => const ExportState();

  void updateRequest(ExportRequest request) {
    state = state.copyWith(request: request, clearError: true);
    _schedulePreview();
  }

  void _schedulePreview() {
    Future.microtask(refreshPreview);
  }

  Future<void> refreshPreview() async {
    state = state.copyWith(isPreviewLoading: true, clearError: true);
    try {
      final preview = await fetchExportPreview(
        state.request,
        client: ref.read(apiClientProvider),
      );
      state = state.copyWith(preview: preview, isPreviewLoading: false);
    } catch (error) {
      state = state.copyWith(
        isPreviewLoading: false,
        error: _friendlyError(error),
      );
    }
  }

  Future<void> exportAndShare() async {
    state = state.copyWith(isExporting: true, clearError: true);
    try {
      final result = await downloadExport(
        state.request,
        client: ref.read(apiClientProvider),
      );
      await _shareFile(result);
      state = state.copyWith(isExporting: false);
    } catch (error) {
      state = state.copyWith(
        isExporting: false,
        error: _friendlyError(error),
      );
    }
  }

  Future<void> _shareFile(ExportDownloadResult result) async {
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(result.bytes), name: result.filename, mimeType: result.mimeType)],
        text: 'Exportacion Heft',
      );
      return;
    }

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${result.filename}');
    await file.writeAsBytes(result.bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: result.mimeType, name: result.filename)],
      text: 'Exportacion Heft',
    );
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      return friendlyExportError(error);
    }
    return error.toString();
  }
}

String friendlyExportError(DioException e) {
  final status = e.response?.statusCode;
  if (status == 404) {
    return 'El servidor aún no tiene activada la exportación de datos.\n'
        'Despliega el backend actualizado en Render o usa API_BASE_URL apuntando a tu servidor local.';
  }
  if (status == 401) {
    return 'Sesión expirada. Vuelve a iniciar sesión.';
  }
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.connectionTimeout) {
    return 'No hay conexión con el servidor. Comprueba tu red o que el backend está en marcha.';
  }
  final data = e.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String) return detail;
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) {
        return value.first.toString();
      }
      if (value is String) return value;
    }
  }
  return 'No se pudo completar la exportación.';
}

final exportProvider = NotifierProvider<ExportNotifier, ExportState>(() {
  return ExportNotifier();
});
