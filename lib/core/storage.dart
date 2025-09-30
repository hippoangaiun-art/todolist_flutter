import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';

Future<List<Todo>> fetchTodos() async {
  try {
    final jsonStr = await Const.todoLists.value;
    if (jsonStr.isEmpty) return [];
    final List<dynamic> jsonList = jsonDecode(jsonStr);
    return jsonList.map((e) => Todo.fromJson(e)).toList();
  } catch (e) {
    return [];
  }
}


Future<void> saveTodos(List<Todo> todos) async {
  final List<Map<String, dynamic>> jsonList =
  todos.map((t) => t.toJson()).toList();
  final jsonStr = jsonEncode(jsonList);
  await Const.todoLists.setValue(jsonStr);
}

