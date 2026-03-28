import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/todo_rules.dart';
import 'package:todolist/models/todo_item_v2.dart';

void main() {
  TodoItemV2 createTodo({
    required String id,
    required DateTime endAt,
    bool done = false,
  }) {
    final now = DateTime(2026, 3, 24, 10, 0);
    return TodoItemV2(
      id: id,
      title: id,
      done: done,
      endAt: endAt,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('结束时间排序遵循未完成优先并按时间升序', () {
    final morning = createTodo(id: 'morning', endAt: DateTime(2026, 3, 24, 9));
    final noon = createTodo(id: 'noon', endAt: DateTime(2026, 3, 24, 12));
    final doneEarly = createTodo(
      id: 'doneEarly',
      endAt: DateTime(2026, 3, 24, 8),
      done: true,
    );

    final sorted = TodoRules.sortByEndAt([noon, doneEarly, morning]);

    expect(sorted.map((e) => e.id).toList(), ['morning', 'noon', 'doneEarly']);
  });

  test('按日期模式仅返回目标日期的待办', () {
    final todoA = createTodo(id: 'a', endAt: DateTime(2026, 3, 24, 9));
    final todoB = createTodo(id: 'b', endAt: DateTime(2026, 3, 25, 9));

    final result = TodoRules.resolveForDate([todoA, todoB], DateTime(2026, 3, 24));

    expect(result.length, 1);
    expect(result.first.id, 'a');
  });

  test('切换完成状态后 done 字段应翻转', () {
    final todo = createTodo(id: 'x', endAt: DateTime(2026, 3, 24, 11));

    final toggled = TodoRules.toggleDone(todo);

    expect(toggled.done, true);
  });
}
