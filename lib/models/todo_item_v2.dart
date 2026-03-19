class TodoItemV2 {
  final String id;
  final String title;
  final bool done;
  final DateTime date;
  final List<int> repeatWeekdays;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoItemV2({
    required this.id,
    required this.title,
    required this.done,
    required this.date,
    required this.repeatWeekdays,
    required this.createdAt,
    required this.updatedAt,
  });

  TodoItemV2 copyWith({
    String? id,
    String? title,
    bool? done,
    DateTime? date,
    List<int>? repeatWeekdays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItemV2(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      date: date ?? this.date,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'date': date.toIso8601String(),
    'repeatWeekdays': repeatWeekdays,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TodoItemV2.fromJson(Map<String, dynamic> json) {
    final repeat = (json['repeatWeekdays'] as List<dynamic>? ?? const [])
        .map((e) => e as int)
        .toList();
    return TodoItemV2(
      id: json['id'] as String,
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
      repeatWeekdays: repeat,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
