class CourseMeeting {
  final int weekday;
  final int startSection;
  final int endSection;
  final int weekStart;
  final int weekEnd;

  const CourseMeeting({
    required this.weekday,
    required this.startSection,
    required this.endSection,
    required this.weekStart,
    required this.weekEnd,
  });

  CourseMeeting copyWith({
    int? weekday,
    int? startSection,
    int? endSection,
    int? weekStart,
    int? weekEnd,
  }) {
    return CourseMeeting(
      weekday: weekday ?? this.weekday,
      startSection: startSection ?? this.startSection,
      endSection: endSection ?? this.endSection,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
    );
  }

  Map<String, dynamic> toJson() => {
    'weekday': weekday,
    'startSection': startSection,
    'endSection': endSection,
    'weekStart': weekStart,
    'weekEnd': weekEnd,
  };

  factory CourseMeeting.fromJson(Map<String, dynamic> json) {
    return CourseMeeting(
      weekday: json['weekday'] as int,
      startSection: json['startSection'] as int,
      endSection: json['endSection'] as int,
      weekStart: json['weekStart'] as int,
      weekEnd: json['weekEnd'] as int,
    );
  }
}

class Course {
  final String id;
  final String name;
  final String classroom;
  final String location;
  final List<CourseMeeting> meetings;

  const Course({
    required this.id,
    required this.name,
    required this.classroom,
    required this.location,
    required this.meetings,
  });

  Course copyWith({
    String? id,
    String? name,
    String? classroom,
    String? location,
    List<CourseMeeting>? meetings,
  }) {
    return Course(
      id: id ?? this.id,
      name: name ?? this.name,
      classroom: classroom ?? this.classroom,
      location: location ?? this.location,
      meetings: meetings ?? this.meetings,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'classroom': classroom,
    'location': location,
    'meetings': meetings.map((e) => e.toJson()).toList(),
  };

  factory Course.fromJson(Map<String, dynamic> json) {
    final meetingsRaw = json['meetings'] as List<dynamic>? ?? const [];
    return Course(
      id: json['id'] as String,
      name: json['name'] as String,
      classroom: json['classroom'] as String? ?? '',
      location: json['location'] as String? ?? '',
      meetings: meetingsRaw
          .map((e) => CourseMeeting.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
