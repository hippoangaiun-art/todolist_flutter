class TodoItemV2 {
  final String id;
  final String title;
  final bool done;
  final DateTime endAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TodoItemV2({
    required this.id,
    required this.title,
    required this.done,
    required this.endAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TodoItemV2 copyWith({
    String? id,
    String? title,
    bool? done,
    DateTime? endAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItemV2(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      endAt: endAt ?? this.endAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'done': done,
    'endAt': endAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory TodoItemV2.fromJson(Map<String, dynamic> json) {
    final rawEndAt = json['endAt'] as String? ?? json['date'] as String?;
    final fallback = DateTime.now();
    return TodoItemV2(
      id: json['id'] as String,
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      endAt: rawEndAt == null ? fallback : DateTime.parse(rawEndAt),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
