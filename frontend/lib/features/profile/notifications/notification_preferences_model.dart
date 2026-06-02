/// Local model that mirrors the backend UserNotificationPreferences.
class NotificationPreferences {
  final bool allEnabled;

  // Workout
  final bool workoutEnabled;
  final List<int> workoutDays;
  final int workoutHour;
  final int workoutMinute;

  // Body progress
  final bool bodyProgressEnabled;
  final String bodyProgressFrequency;
  final int bodyProgressDayOfWeek;
  final int bodyProgressHour;
  final int bodyProgressMinute;

  // Weekly summary
  final bool weeklySummaryEnabled;
  final int weeklySummaryDayOfWeek;
  final int weeklySummaryHour;
  final int weeklySummaryMinute;

  // Inactivity
  final bool inactivityEnabled;
  final int inactivityThresholdDays;

  final String timezone;

  const NotificationPreferences({
    this.allEnabled = true,
    this.workoutEnabled = true,
    this.workoutDays = const [0, 1, 2, 3, 4],
    this.workoutHour = 9,
    this.workoutMinute = 0,
    this.bodyProgressEnabled = true,
    this.bodyProgressFrequency = 'weekly',
    this.bodyProgressDayOfWeek = 0,
    this.bodyProgressHour = 10,
    this.bodyProgressMinute = 0,
    this.weeklySummaryEnabled = true,
    this.weeklySummaryDayOfWeek = 6,
    this.weeklySummaryHour = 20,
    this.weeklySummaryMinute = 0,
    this.inactivityEnabled = true,
    this.inactivityThresholdDays = 3,
    this.timezone = 'UTC',
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      allEnabled: json['all_enabled'] as bool? ?? true,
      workoutEnabled: json['workout_enabled'] as bool? ?? true,
      workoutDays: (json['workout_days'] as List?)?.cast<int>() ?? [0, 1, 2, 3, 4],
      workoutHour: json['workout_hour'] as int? ?? 9,
      workoutMinute: json['workout_minute'] as int? ?? 0,
      bodyProgressEnabled: json['body_progress_enabled'] as bool? ?? true,
      bodyProgressFrequency: json['body_progress_frequency'] as String? ?? 'weekly',
      bodyProgressDayOfWeek: json['body_progress_day_of_week'] as int? ?? 0,
      bodyProgressHour: json['body_progress_hour'] as int? ?? 10,
      bodyProgressMinute: json['body_progress_minute'] as int? ?? 0,
      weeklySummaryEnabled: json['weekly_summary_enabled'] as bool? ?? true,
      weeklySummaryDayOfWeek: json['weekly_summary_day_of_week'] as int? ?? 6,
      weeklySummaryHour: json['weekly_summary_hour'] as int? ?? 20,
      weeklySummaryMinute: json['weekly_summary_minute'] as int? ?? 0,
      inactivityEnabled: json['inactivity_enabled'] as bool? ?? true,
      inactivityThresholdDays: json['inactivity_threshold_days'] as int? ?? 3,
      timezone: json['timezone'] as String? ?? 'UTC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'all_enabled': allEnabled,
      'workout_enabled': workoutEnabled,
      'workout_days': workoutDays,
      'workout_hour': workoutHour,
      'workout_minute': workoutMinute,
      'body_progress_enabled': bodyProgressEnabled,
      'body_progress_frequency': bodyProgressFrequency,
      'body_progress_day_of_week': bodyProgressDayOfWeek,
      'body_progress_hour': bodyProgressHour,
      'body_progress_minute': bodyProgressMinute,
      'weekly_summary_enabled': weeklySummaryEnabled,
      'weekly_summary_day_of_week': weeklySummaryDayOfWeek,
      'weekly_summary_hour': weeklySummaryHour,
      'weekly_summary_minute': weeklySummaryMinute,
      'inactivity_enabled': inactivityEnabled,
      'inactivity_threshold_days': inactivityThresholdDays,
      'timezone': timezone,
    };
  }

  NotificationPreferences copyWith({
    bool? allEnabled,
    bool? workoutEnabled,
    List<int>? workoutDays,
    int? workoutHour,
    int? workoutMinute,
    bool? bodyProgressEnabled,
    String? bodyProgressFrequency,
    int? bodyProgressDayOfWeek,
    int? bodyProgressHour,
    int? bodyProgressMinute,
    bool? weeklySummaryEnabled,
    int? weeklySummaryDayOfWeek,
    int? weeklySummaryHour,
    int? weeklySummaryMinute,
    bool? inactivityEnabled,
    int? inactivityThresholdDays,
    String? timezone,
  }) {
    return NotificationPreferences(
      allEnabled: allEnabled ?? this.allEnabled,
      workoutEnabled: workoutEnabled ?? this.workoutEnabled,
      workoutDays: workoutDays ?? this.workoutDays,
      workoutHour: workoutHour ?? this.workoutHour,
      workoutMinute: workoutMinute ?? this.workoutMinute,
      bodyProgressEnabled: bodyProgressEnabled ?? this.bodyProgressEnabled,
      bodyProgressFrequency: bodyProgressFrequency ?? this.bodyProgressFrequency,
      bodyProgressDayOfWeek: bodyProgressDayOfWeek ?? this.bodyProgressDayOfWeek,
      bodyProgressHour: bodyProgressHour ?? this.bodyProgressHour,
      bodyProgressMinute: bodyProgressMinute ?? this.bodyProgressMinute,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      weeklySummaryDayOfWeek: weeklySummaryDayOfWeek ?? this.weeklySummaryDayOfWeek,
      weeklySummaryHour: weeklySummaryHour ?? this.weeklySummaryHour,
      weeklySummaryMinute: weeklySummaryMinute ?? this.weeklySummaryMinute,
      inactivityEnabled: inactivityEnabled ?? this.inactivityEnabled,
      inactivityThresholdDays: inactivityThresholdDays ?? this.inactivityThresholdDays,
      timezone: timezone ?? this.timezone,
    );
  }
}
