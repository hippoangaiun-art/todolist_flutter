import 'package:todolist/models/todo_item_v2.dart';

class TodoRules {
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static bool isVisibleOnDate(TodoItemV2 todo, DateTime targetDate) {
    final target = normalize(targetDate);
    final endDate = normalize(todo.endAt);
    return target == endDate;
  }

  static TodoItemV2 toggleDone(TodoItemV2 todo) {
    return todo.copyWith(done: !todo.done, updatedAt: DateTime.now());
  }

  static List<TodoItemV2> sortByEndAt(List<TodoItemV2> todos) {
    final sorted = [...todos];
    sorted.sort((a, b) {
      if (a.done != b.done) {
        return a.done ? 1 : -1;
      }
      final byEndAt = a.endAt.compareTo(b.endAt);
      if (byEndAt != 0) {
        return byEndAt;
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return sorted;
  }

  static List<TodoItemV2> resolveForDate(
    List<TodoItemV2> todos,
    DateTime targetDate,
  ) {
    final filtered = todos
        .where((todo) => isVisibleOnDate(todo, targetDate))
        .toList();
    return sortByEndAt(filtered);
  }
}
