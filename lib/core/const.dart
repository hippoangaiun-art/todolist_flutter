import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todolist/utils/preferences.dart';

final logger = Logger();

Future<int> getAppVersionCode() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return int.parse(packageInfo.version);
}

Future<void> checkUpdate() async {}

class Todo {
  final String title;
  final bool done;
  final int? weekday;
  final TimeOfDay? time;

  Todo({required this.title, required this.done, this.weekday, this.time});

  Map<String, dynamic> toJson() => {
    'title': title,
    'done': done,
    'weekday': weekday,
    'hour': time?.hour,
    'minute': time?.minute,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'] as String,
      done: json['done'] as bool? ?? false,
      weekday: json['weekday'] as int?,
      time: (json['hour'] != null && json['minute'] != null)
          ? TimeOfDay(hour: json['hour'] as int, minute: json['minute'] as int)
          : null,
    );
  }
}

class Const {
  static final githubUrl =
      'https://github.com/hippoangaiun-art/todolist_flutter';

  static final todoLists = PrefField<String>(
    'todolist',
    '[{"title":"Welcome","done":false,"weekday":1,"hour":9,"minute":0}]',
  );
  static final todoListV2 = PrefField<String>('todos_v2', '[]');
  static final scheduleCourses = PrefField<String>('schedule_courses_v1', '[]');
  static final scheduleSections = PrefField<String>(
    'schedule_sections_v1',
    '[]',
  );
  static final scheduleSettings = PrefField<String>(
    'schedule_settings_v1',
    '{}',
  );

  static final appName = 'ToDo List';
}
