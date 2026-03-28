import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/pages/todo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String buildTodosPayload(List<Map<String, dynamic>> todos) {
    return jsonEncode(todos);
  }

  Map<String, dynamic> createTodo({
    required String id,
    required String title,
    required bool done,
    required DateTime endAt,
  }) {
    final base = DateTime(2026, 3, 24, 10);
    return {
      'id': id,
      'title': title,
      'done': done,
      'endAt': endAt.toIso8601String(),
      'createdAt': base.toIso8601String(),
      'updatedAt': base.toIso8601String(),
    };
  }

  Future<void> pumpTodoPage(WidgetTester tester, String payload) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({'todos_v2': payload});
    await Const.todoListV2.setValue(payload);
    await tester.pumpWidget(const MaterialApp(home: TodoPage()));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('待办页可正常渲染并显示新增入口', (tester) async {
    await pumpTodoPage(tester, '[]');

    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('暂无待办'), findsOneWidget);
  });

  testWidgets('全部模式默认显示结束时间前后的所有待办', (tester) async {
    final now = DateTime.now();
    final payload = buildTodosPayload([
      createTodo(
        id: '1',
        title: '过期任务',
        done: false,
        endAt: now.subtract(const Duration(days: 2)),
      ),
      createTodo(
        id: '2',
        title: '未来任务',
        done: false,
        endAt: now.add(const Duration(days: 2)),
      ),
    ]);

    await pumpTodoPage(tester, payload);

    expect(find.text('过期任务'), findsOneWidget);
    expect(find.text('未来任务'), findsOneWidget);
  });

  testWidgets('搜索可按标题实时过滤列表', (tester) async {
    final now = DateTime.now();
    final payload = buildTodosPayload([
      createTodo(id: '1', title: '高数作业', done: false, endAt: now),
      createTodo(id: '2', title: '英语听力', done: false, endAt: now),
    ]);

    await pumpTodoPage(tester, payload);
    await tester.enterText(find.byType(TextField).first, '英语');
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('英语听力'), findsOneWidget);
    expect(find.text('高数作业'), findsNothing);
  });

  testWidgets('按日期模式可按当天过滤待办', (tester) async {
    final now = DateTime.now();
    final payload = buildTodosPayload([
      createTodo(id: '1', title: '今天任务', done: false, endAt: now),
      createTodo(
        id: '2',
        title: '昨天任务',
        done: false,
        endAt: now.subtract(const Duration(days: 1)),
      ),
    ]);

    await pumpTodoPage(tester, payload);
    await tester.tap(find.text('按日期'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('今天任务'), findsOneWidget);
    expect(find.text('昨天任务'), findsNothing);
  });

  testWidgets('已完成事项默认折叠并可展开', (tester) async {
    final now = DateTime.now();
    final payload = buildTodosPayload([
      createTodo(id: '1', title: '未完成任务', done: false, endAt: now),
      createTodo(id: '2', title: '已完成任务', done: true, endAt: now),
    ]);

    await pumpTodoPage(tester, payload);

    expect(find.text('已完成事项 (1)'), findsOneWidget);
    expect(find.text('已完成任务'), findsNothing);

    await tester.tap(find.text('已完成事项 (1)'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('已完成任务'), findsOneWidget);
  });
}
