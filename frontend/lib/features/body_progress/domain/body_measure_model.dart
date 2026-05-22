class BodyMeasureEntry {
  final int id;
  final double weight;
  final DateTime date;
  final String notes;
  final String? photoUrl;
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
    this.photoUrl,
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

  bool get hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

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
    return BodyMeasureEntry(
      id: json['id'] as int,
      weight: (json['weight'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      notes: (json['notes'] as String?) ?? '',
      photoUrl: json['photo'] as String?,
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

  static double? _optionalDouble(dynamic value) {
    if (value == null) return null;
    return (value as num).toDouble();
  }
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
