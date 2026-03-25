import 'package:todolist/models/course.dart';

class ScheduleRules {
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int resolveWeekFromDate(DateTime date, DateTime? firstWeekDate) {
    if (firstWeekDate == null) {
      return 1;
    }
    final diff = normalize(date).difference(normalize(firstWeekDate)).inDays;
    if (diff < 0) {
      return 1;
    }
    return diff ~/ 7 + 1;
  }

  static DateTime? weekdayDateInWeek({
    required int weekday,
    required int selectedWeek,
    required DateTime? firstWeekDate,
  }) {
    if (firstWeekDate == null) {
      return null;
    }
    final safeWeek = selectedWeek < 1 ? 1 : selectedWeek;
    final start = normalize(
      firstWeekDate,
    ).add(Duration(days: (safeWeek - 1) * 7));
    return start.add(Duration(days: weekday - 1));
  }

  static bool isMeetingVisible(CourseMeeting meeting, int selectedWeek) {
    return selectedWeek >= meeting.weekStart && selectedWeek <= meeting.weekEnd;
  }
}
