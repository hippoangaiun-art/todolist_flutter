import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/excel_importer.dart';

void main() {
  group('CourseImporter.mergeWithExisting', () {
    test('相同星期、时间、标题时应去重', () {
      final existing = [
        Todo(
          title: '高等数学 教一-101',
          done: false,
          weekday: 1,
          time: const TimeOfDay(hour: 8, minute: 0),
        ),
      ];
      final imported = [
        Todo(
          title: '高等数学 教一-101',
          done: false,
          weekday: 1,
          time: const TimeOfDay(hour: 8, minute: 0),
        ),
      ];

      final merged = CourseImporter.mergeWithExisting(existing, imported);
      expect(merged.length, 1);
    });

    test('同名但不同时间应保留', () {
      final existing = [
        Todo(
          title: '大学英语 教三-202',
          done: false,
          weekday: 2,
          time: const TimeOfDay(hour: 8, minute: 0),
        ),
      ];
      final imported = [
        Todo(
          title: '大学英语 教三-202',
          done: false,
          weekday: 2,
          time: const TimeOfDay(hour: 9, minute: 50),
        ),
      ];

      final merged = CourseImporter.mergeWithExisting(existing, imported);
      expect(merged.length, 2);
    });

    test('同名同时间但不同星期应保留', () {
      final existing = [
        Todo(
          title: '线性代数 教二-305',
          done: false,
          weekday: 3,
          time: const TimeOfDay(hour: 10, minute: 40),
        ),
      ];
      final imported = [
        Todo(
          title: '线性代数 教二-305',
          done: false,
          weekday: 5,
          time: const TimeOfDay(hour: 10, minute: 40),
        ),
      ];

      final merged = CourseImporter.mergeWithExisting(existing, imported);
      expect(merged.length, 2);
    });
  });
}
