import 'package:todolist/models/todo_item_v2.dart';

class TodoOccurrence {
  final TodoItemV2 todo;
  final DateTime date;
  final bool done;

  const TodoOccurrence({
    required this.todo,
    required this.date,
    required this.done,
  });
}

class TodoRules {
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static String dateKey(DateTime date) {
    final normalized = normalize(date);
    return '${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}';
  }

  static bool isVisibleOnDate(TodoItemV2 todo, DateTime targetDate) {
    final todoDate = normalize(todo.date);
    final selectedDate = normalize(targetDate);
    if (todo.repeatWeekdays.isEmpty) {
      return todoDate == selectedDate;
    }
    if (selectedDate.isBefore(todoDate)) {
      return false;
    }
    return todo.repeatWeekdays.contains(selectedDate.weekday);
  }

  static bool isDoneOnDate(TodoItemV2 todo, DateTime targetDate) {
    if (todo.repeatWeekdays.isEmpty) {
      return todo.done;
    }
    return todo.completedDates.contains(dateKey(targetDate));
  }

  static TodoItemV2 toggleDoneOnDate(TodoItemV2 todo, DateTime targetDate) {
    if (todo.repeatWeekdays.isEmpty) {
      return todo.copyWith(done: !todo.done, updatedAt: DateTime.now());
    }
    final key = dateKey(targetDate);
    final next = [...todo.completedDates];
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    next.sort();
    return todo.copyWith(completedDates: next, updatedAt: DateTime.now());
  }

  static List<TodoOccurrence> resolveForDate(List<TodoItemV2> todos, DateTime targetDate) {
    final filtered = todos
        .where((todo) => isVisibleOnDate(todo, targetDate))
        .map(
          (todo) => TodoOccurrence(
            todo: todo,
            date: normalize(targetDate),
            done: isDoneOnDate(todo, targetDate),
          ),
        )
        .toList();
    filtered.sort((a, b) => b.todo.updatedAt.compareTo(a.todo.updatedAt));
    return filtered;
  }
}
