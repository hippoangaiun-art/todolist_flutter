import 'dart:convert';

import 'package:todolist/core/const.dart';
import 'package:todolist/models/todo_item_v2.dart';

class TodoRepository {
  Future<List<TodoItemV2>> fetchAll() async {
    final raw = await Const.todoListV2.value;
    if (raw.trim().isEmpty) {
      return [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => TodoItemV2.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<TodoItemV2> todos) async {
    final payload = jsonEncode(todos.map((e) => e.toJson()).toList());
    await Const.todoListV2.setValue(payload);
  }
}
