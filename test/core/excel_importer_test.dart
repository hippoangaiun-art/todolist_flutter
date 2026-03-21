import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/excel_importer.dart';
import 'package:todolist/models/course.dart';
import 'package:todolist/models/section_slot.dart';

void main() {
  test('Excel 导入可按相邻节次合并时段', () async {
    final excel = Excel.createExcel();
    final sheet = excel.tables[excel.tables.keys.first]!;

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('节次');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('星期一');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('1');
    sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue('高等数学\n1-18周\n教一-101');
    sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('2');
    sheet.cell(CellIndex.indexByString('B3')).value = TextCellValue('高等数学\n1-18周\n教一-101');

    final bytes = excel.encode()!;
    final sections = [
      const SectionSlot(number: 1, startMinutes: 480, endMinutes: 525),
      const SectionSlot(number: 2, startMinutes: 530, endMinutes: 575),
    ];

    final courses = await CourseExcelImporter.importFromBytes(bytes: bytes, sections: sections);

    expect(courses.length, 1);
    expect(courses.first.meetings.length, 1);
    expect(courses.first.meetings.first.startSection, 1);
    expect(courses.first.meetings.first.endSection, 2);
  });

  test('导入合并应去除重复课程时段', () {
    final existing = [
      Course(
        id: '1',
        name: '线性代数',
        classroom: '教一-101',
        location: '主楼',
        meetings: const [
          CourseMeeting(weekday: 1, startSection: 1, endSection: 2, weekStart: 1, weekEnd: 18),
        ],
      ),
    ];

    final imported = [
      Course(
        id: '2',
        name: '线性代数',
        classroom: '教一-101',
        location: '主楼',
        meetings: const [
          CourseMeeting(weekday: 1, startSection: 1, endSection: 2, weekStart: 1, weekEnd: 18),
          CourseMeeting(weekday: 3, startSection: 3, endSection: 4, weekStart: 1, weekEnd: 18),
        ],
      ),
    ];

    final merged = CourseExcelImporter.mergeWithExisting(existing, imported);

    expect(merged.length, 1);
    expect(merged.first.meetings.length, 2);
  });
}
