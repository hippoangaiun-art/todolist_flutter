class SectionSlot {
  final int number;
  final int startMinutes;
  final int endMinutes;

  const SectionSlot({
    required this.number,
    required this.startMinutes,
    required this.endMinutes,
  });

  int get durationMinutes => endMinutes - startMinutes;

  SectionSlot copyWith({
    int? number,
    int? startMinutes,
    int? endMinutes,
  }) {
    return SectionSlot(
      number: number ?? this.number,
      startMinutes: startMinutes ?? this.startMinutes,
      endMinutes: endMinutes ?? this.endMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'startMinutes': startMinutes,
    'endMinutes': endMinutes,
  };

  factory SectionSlot.fromJson(Map<String, dynamic> json) {
    return SectionSlot(
      number: json['number'] as int,
      startMinutes: json['startMinutes'] as int,
      endMinutes: json['endMinutes'] as int,
    );
  }
}
