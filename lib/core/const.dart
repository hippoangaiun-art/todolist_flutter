import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:todolist/utils/preferences.dart';

final logger = Logger();

Future<int> getAppVersionCode() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return int.parse(packageInfo.version); // 构建号（如 12）
}



Future<void> checkUpdate() async {
  //TODO 写检查更新
}

class Todo {
  final String title;
  final bool done;
  final int? weekday; // 1=周一, 7=周日
  final TimeOfDay? time;

  Todo({
    required this.title,
    required this.done,
    this.weekday,
    this.time,
  });

  // json 序列化
  Map<String, dynamic> toJson() => {
    'title': title,
    'done': done,
    'weekday': weekday,
    'hour': time?.hour,
    'minute': time?.minute,
  };

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      done: json['done'],
      weekday: json['weekday'],
      time: (json['hour'] != null && json['minute'] != null)
          ? TimeOfDay(hour: json['hour'], minute: json['minute'])
          : null,
    );
  }
}


class Const {
  static final githubUrl = "https://github.com/hippoangaiun-art/todolist_flutter";
  static final todoLists = PrefField<String>("todolist", """
  [
  {
    "title": "Welcome",
    "done": false,
    "weekday": 1,
    "hour": 9,
    "minute": 0
  }
]

  """);

  static final appName = "ToDo List";
}
