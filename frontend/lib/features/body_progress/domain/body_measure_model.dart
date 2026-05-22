/// Máximo de fotos por registro de peso/medidas (debe coincidir con el backend).
const int kMaxBodyEntryPhotos = 4;

/// Lista: más antiguo primero (izquierda en gráficos).
int compareBodyMeasureEntriesAsc(BodyMeasureEntry a, BodyMeasureEntry b) {
  final byDate = a.date.compareTo(b.date);
  if (byDate != 0) return byDate;
  return a.id.compareTo(b.id);
}

/// Lista: más reciente primero.
int compareBodyMeasureEntriesDesc(BodyMeasureEntry a, BodyMeasureEntry b) {
  final byDate = b.date.compareTo(a.date);
  if (byDate != 0) return byDate;
  return b.id.compareTo(a.id);
}

class BodyMeasureEntry {
  final int id;
  final double weight;
  final DateTime date;
  final String notes;
  final List<String> photoUrls;
  final double? neckCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? shouldersCm;
  final double? bicepLeftCm;
  final double? bicepRightCm;
  final double? thighLeftCm;
  final double? thighRightCm;

  const BodyMeasureEntry({
    required this.id,
    required this.weight,
    required this.date,
    this.notes = '',
    this.photoUrls = const [],
    this.neckCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.shouldersCm,
    this.bicepLeftCm,
    this.bicepRightCm,
    this.thighLeftCm,
    this.thighRightCm,
  });

  bool get hasPhoto => photoUrls.isNotEmpty;

  /// Primera foto (compatibilidad con API `photo`).
  String? get photoUrl => photoUrls.isNotEmpty ? photoUrls.first : null;

  bool get hasBodyMeasurements =>
      neckCm != null ||
      chestCm != null ||
      waistCm != null ||
      hipsCm != null ||
      shouldersCm != null ||
      bicepLeftCm != null ||
      bicepRightCm != null ||
      thighLeftCm != null ||
      thighRightCm != null;

  factory BodyMeasureEntry.fromJson(Map<String, dynamic> json) {
    final photos = _parsePhotoUrls(json);
    return BodyMeasureEntry(
      id: json['id'] as int,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: (json['notes'] as String?) ?? '',
      photoUrls: photos,
      neckCm: _optionalDouble(json['neck_cm']),
      chestCm: _optionalDouble(json['chest_cm']),
      waistCm: _optionalDouble(json['waist_cm']),
      hipsCm: _optionalDouble(json['hips_cm']),
      shouldersCm: _optionalDouble(json['shoulders_cm']),
      bicepLeftCm: _optionalDouble(json['bicep_left_cm']),
      bicepRightCm: _optionalDouble(json['bicep_right_cm']),
      thighLeftCm: _optionalDouble(json['thigh_left_cm']),
      thighRightCm: _optionalDouble(json['thigh_right_cm']),
    );
  }

  static List<String> _parsePhotoUrls(Map<String, dynamic> json) {
    final raw = json['photos'];
    if (raw is List) {
      return raw
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList(growable: false);
    }
    final single = json['photo'] as String?;
    if (single != null && single.isNotEmpty) {
      return [single];
    }
    return const [];
  }

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
}

/// Una foto concreta dentro de un registro (para el álbum).
class AlbumPhotoItem {
  final BodyMeasureEntry entry;
  final int photoIndex;
  final String url;

  const AlbumPhotoItem({
    required this.entry,
    required this.photoIndex,
    required this.url,
  });

  int get entryId => entry.id;
}

List<AlbumPhotoItem> flattenAlbumPhotos(List<BodyMeasureEntry> entries) {
  final items = <AlbumPhotoItem>[];
  final sorted = [...entries]..sort(compareBodyMeasureEntriesDesc);
  for (final entry in sorted) {
    for (var i = 0; i < entry.photoUrls.length; i++) {
      items.add(
        AlbumPhotoItem(entry: entry, photoIndex: i, url: entry.photoUrls[i]),
      );
    }
  }
  return items;
}

class WeightHistoryPoint {
  final DateTime date;
  final double weight;

  const WeightHistoryPoint({required this.date, required this.weight});

  factory WeightHistoryPoint.fromJson(Map<String, dynamic> json) {
    return WeightHistoryPoint(
      date: DateTime.parse(json['date'] as String),
      weight: (json['weight'] as num).toDouble(),
    );
  }
}
