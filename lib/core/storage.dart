import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';

Future<List<Todo>> fetchTodos() async {
  try {
    final jsonStr = await Const.todoLists.value;
    final List<dynamic> list = json.decode(jsonStr);

    return list.map((item) {
      final name = item['name'] ?? '未命名';
      final done = item['done'] ?? false;
      final ddlStr = item['ddl'] ?? '';
      DateTime? ddl;
      if (ddlStr.isNotEmpty) {
        try {
          ddl = DateTime.parse(ddlStr);
        } catch (_) {
          ddl = null;
        }
      }
      return Todo(title: name, done: done, ddl: ddl);
    }).toList();
  } catch (e) {
    throw Exception('解析待办列表失败: $e');
  }
}

/// 保存待办列表到 Const.todoLists
Future<void> saveTodos(List<Todo> todos) async {
  try {
    final jsonList = todos.map((t) {
      return {
        "name": t.title,
        "done": t.done,
        "ddl": t.ddl?.toIso8601String() ?? "",
      };
    }).toList();

    final jsonStr = json.encode(jsonList);
    await Const.todoLists.setValue(jsonStr);
  } catch (e) {
    debugPrint("保存待办列表失败: $e");
  }
}
