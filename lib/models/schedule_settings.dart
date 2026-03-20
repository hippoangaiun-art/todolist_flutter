class ScheduleSettings {
  final DateTime? firstWeekDate;
  final String themeMode;

  const ScheduleSettings({
    required this.firstWeekDate,
    this.themeMode = 'system',
  });

  ScheduleSettings copyWith({
    DateTime? firstWeekDate,
    String? themeMode,
    bool clearFirstWeekDate = false,
  }) {
    return ScheduleSettings(
      firstWeekDate: clearFirstWeekDate ? null : (firstWeekDate ?? this.firstWeekDate),
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstWeekDate': firstWeekDate?.toIso8601String(),
    'themeMode': themeMode,
  };

  factory ScheduleSettings.fromJson(Map<String, dynamic> json) {
    final rawDate = json['firstWeekDate'] as String?;
    return ScheduleSettings(
      firstWeekDate: rawDate == null || rawDate.isEmpty ? null : DateTime.parse(rawDate),
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }
}
