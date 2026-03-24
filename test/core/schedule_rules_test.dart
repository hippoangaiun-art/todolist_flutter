import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/schedule_rules.dart';
import 'package:todolist/models/course.dart';

void main() {
  test('根据第一周日期计算当前周次', () {
    final week = ScheduleRules.resolveWeekFromDate(
      DateTime(2026, 3, 24),
      DateTime(2026, 3, 10),
    );

    expect(week, 3);
  });

  test('第一周日期为空时默认第一周', () {
    final week = ScheduleRules.resolveWeekFromDate(DateTime(2026, 3, 24), null);
    expect(week, 1);
  });

  test('周次和星期可换算到具体日期', () {
    final date = ScheduleRules.weekdayDateInWeek(
      weekday: 3,
      selectedWeek: 2,
      firstWeekDate: DateTime(2026, 3, 2),
    );

    expect(date, DateTime(2026, 3, 11));
  });

  test('课程时段按周次判断可见性', () {
    const meeting = CourseMeeting(
      weekday: 1,
      startSection: 1,
      endSection: 2,
      weekStart: 5,
      weekEnd: 18,
    );

    expect(ScheduleRules.isMeetingVisible(meeting, 4), false);
    expect(ScheduleRules.isMeetingVisible(meeting, 5), true);
    expect(ScheduleRules.isMeetingVisible(meeting, 19), false);
  });
}
