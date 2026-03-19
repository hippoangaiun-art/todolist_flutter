import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/todo_rules.dart';
import 'package:todolist/models/todo_item_v2.dart';

void main() {
  TodoItemV2 createTodo({
    required DateTime date,
    required List<int> repeatWeekdays,
    bool done = false,
    List<String> completedDates = const [],
  }) {
    final now = DateTime(2026, 3, 24, 10);
    return TodoItemV2(
      id: '1',
      title: 'todo',
      done: done,
      date: date,
      repeatWeekdays: repeatWeekdays,
      completedDates: completedDates,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('重复任务在开始日期前不显示', () {
    final todo = createTodo(
      date: DateTime(2026, 3, 20),
      repeatWeekdays: const [1, 5],
    );

    final visibleBefore = TodoRules.isVisibleOnDate(todo, DateTime(2026, 3, 16));
    final visibleAfter = TodoRules.isVisibleOnDate(todo, DateTime(2026, 3, 23));

    expect(visibleBefore, false);
    expect(visibleAfter, true);
  });

  test('重复任务完成状态按日期存储不会回退', () {
    final todo = createTodo(
      date: DateTime(2026, 3, 20),
      repeatWeekdays: const [1],
    );

    final doneOn24 = TodoRules.toggleDoneOnDate(todo, DateTime(2026, 3, 24));

    expect(TodoRules.isDoneOnDate(doneOn24, DateTime(2026, 3, 24)), true);
    expect(TodoRules.isDoneOnDate(doneOn24, DateTime(2026, 3, 31)), false);
  });

  test('单次任务使用全局完成状态', () {
    final todo = createTodo(
      date: DateTime(2026, 3, 24),
      repeatWeekdays: const [],
      done: false,
    );

    final toggled = TodoRules.toggleDoneOnDate(todo, DateTime(2026, 3, 24));
    expect(toggled.done, true);
    expect(TodoRules.isDoneOnDate(toggled, DateTime(2026, 3, 25)), true);
  });
}
