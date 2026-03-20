import 'package:excel/excel.dart';
import 'package:todolist/models/course.dart';
import 'package:todolist/models/section_slot.dart';

class CourseExcelImporter {
  static const Map<String, int> _weekdayMap = {
    '星期一': 1,
    '星期二': 2,
    '星期三': 3,
    '星期四': 4,
    '星期五': 5,
    '星期六': 6,
    '星期日': 7,
    '周一': 1,
    '周二': 2,
    '周三': 3,
    '周四': 4,
    '周五': 5,
    '周六': 6,
    '周日': 7,
  };

  static Future<List<Course>> importFromBytes({
    required List<int> bytes,
    required List<SectionSlot> sections,
  }) async {
    final excel = Excel.decodeBytes(bytes);
    if (excel.tables.isEmpty) {
      return [];
    }
    final sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null) {
      return [];
    }
    return _parseSheet(sheet, sections);
  }

  static List<Course> _parseSheet(Sheet sheet, List<SectionSlot> sections) {
    final sectionNumbers = sections.map((e) => e.number).toSet();
    final headerRowIndex = _findHeaderRow(sheet);
    if (headerRowIndex == null) {
      return [];
    }

    final headerRow = sheet.row(headerRowIndex);
    final weekdayColumns = <int, int>{};
    for (int col = 0; col < headerRow.length; col++) {
      final text = headerRow[col]?.value?.toString() ?? '';
      final weekday = _resolveWeekday(text);
      if (weekday != null) {
        weekdayColumns[col] = weekday;
      }
    }

    final courses = <Course>[];
    int sequence = 0;

    for (int row = headerRowIndex + 1; row < sheet.maxRows; row++) {
      final rowData = sheet.row(row);
      if (rowData.isEmpty) {
        continue;
      }
      final sectionCell = rowData.firstOrNull?.value?.toString() ?? '';
      final sectionMatch = RegExp(r'^(\d+)').firstMatch(sectionCell.trim());
      if (sectionMatch == null) {
        continue;
      }
      final section = int.tryParse(sectionMatch.group(1)!);
      if (section == null) {
        continue;
      }
      if (sectionNumbers.isNotEmpty && !sectionNumbers.contains(section)) {
        continue;
      }

      weekdayColumns.forEach((columnIndex, weekday) {
        if (columnIndex >= rowData.length) {
          return;
        }
        final rawCell = rowData[columnIndex]?.value?.toString() ?? '';
        final cellValue = rawCell.trim();
        if (cellValue.isEmpty) {
          return;
        }

        final blocks = _splitCourseBlocks(cellValue);
        for (final block in blocks) {
          final parsed = _parseBlock(block);
          final now = DateTime.now().microsecondsSinceEpoch;
          sequence += 1;
          courses.add(
            Course(
              id: '${now}_$row$columnIndex$sequence',
              name: parsed.name,
              classroom: parsed.classroom,
              location: parsed.location,
              meetings: [
                CourseMeeting(
                  weekday: weekday,
                  startSection: section,
                  endSection: section,
                  weekStart: parsed.weekStart,
                  weekEnd: parsed.weekEnd,
                ),
              ],
            ),
          );
        }
      });
    }

    return courses;
  }

  static int? _findHeaderRow(Sheet sheet) {
    for (int row = 0; row < sheet.maxRows; row++) {
      final rowData = sheet.row(row);
      for (final cell in rowData) {
        final text = cell?.value?.toString() ?? '';
        if (_resolveWeekday(text) != null) {
          return row;
        }
      }
    }
    return null;
  }

  static int? _resolveWeekday(String text) {
    for (final entry in _weekdayMap.entries) {
      if (text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static List<String> _splitCourseBlocks(String input) {
    return input
        .split(RegExp(r'\n\s*\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static _ParsedBlock _parseBlock(String block) {
    final lines = block
        .split(RegExp(r'\r?\n'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final name = lines.isEmpty ? '未命名课程' : lines.first;
    String classroom = '';
    String location = '';

    for (final line in lines.skip(1)) {
      if (classroom.isEmpty && RegExp(r'[A-Za-z0-9]+[-][A-Za-z0-9]+').hasMatch(line)) {
        classroom = line;
      }
      if (location.isEmpty && RegExp(r'[\u4e00-\u9fa5]').hasMatch(line)) {
        location = line;
      }
    }

    final weekMatch = RegExp(r'(\d+)\s*[-~]\s*(\d+)\s*周').firstMatch(block);
    final weekStart = weekMatch == null ? 1 : int.parse(weekMatch.group(1)!);
    final weekEnd = weekMatch == null ? 18 : int.parse(weekMatch.group(2)!);

    return _ParsedBlock(
      name: name,
      classroom: classroom,
      location: location,
      weekStart: weekStart,
      weekEnd: weekEnd,
    );
  }
}

class _ParsedBlock {
  final String name;
  final String classroom;
  final String location;
  final int weekStart;
  final int weekEnd;

  const _ParsedBlock({
    required this.name,
    required this.classroom,
    required this.location,
    required this.weekStart,
    required this.weekEnd,
  });
}
