import 'package:excel/excel.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/storage.dart';
import 'package:flutter/material.dart';

/// 课程信息
class CourseInfo {
  final String name;        // 课程名称
  final String location;    // 教室位置
  final TimeOfDay time;     // 上课时间
  final int weekday;        // 星期几 (1-7)

  CourseInfo({
    required this.name,
    required this.location,
    required this.time,
    required this.weekday,
  });
}

/// 课程表导入器
class CourseImporter {
  /// 节次时间映射（根据北邮课表标准时间）
  static const Map<String, TimeOfDay> timeSlots = {
    '1': TimeOfDay(hour: 8, minute: 0),
    '2': TimeOfDay(hour: 8, minute: 50),
    '3': TimeOfDay(hour: 9, minute: 50),
    '4': TimeOfDay(hour: 10, minute: 40),
    '5': TimeOfDay(hour: 11, minute: 30),
    '6': TimeOfDay(hour: 13, minute: 0),
    '7': TimeOfDay(hour: 13, minute: 50),
    '8': TimeOfDay(hour: 14, minute: 45),
    '9': TimeOfDay(hour: 15, minute: 40),
    '10': TimeOfDay(hour: 16, minute: 35),
    '11': TimeOfDay(hour: 17, minute: 25),
    '12': TimeOfDay(hour: 18, minute: 30),
    '13': TimeOfDay(hour: 19, minute: 20),
    '14': TimeOfDay(hour: 20, minute: 10),
  };

  /// 星期映射
  static const Map<String, int> weekdayMap = {
    '星期一': 1,
    '星期二': 2,
    '星期三': 3,
    '星期四': 4,
    '星期五': 5,
    '星期六': 6,
    '星期日': 7,
  };

  /// 从 Excel 字节数据导入课程表
  static Future<List<Todo>> importFromBytes(List<int> bytes) async {
    try {
      final excel = Excel.decodeBytes(bytes);
      final sheet = excel.tables[excel.tables.keys.first];

      if (sheet == null) {
        throw Exception('Excel 文件中没有找到工作表');
      }

      return _parseSheet(sheet);
    } catch (e) {
      throw Exception('解析 Excel 文件失败: $e');
    }
  }

  /// 解析工作表
  static List<Todo> _parseSheet(Sheet sheet) {
    final List<Todo> todos = [];

    // 找到星期标题行（第3行，包含"星期一"、"星期二"等）
    int? headerRowIndex;
    for (int i = 0; i < sheet.maxRows; i++) {
      final row = sheet.row(i);
      for (var cell in row) {
        final cellText = cell?.value?.toString() ?? '';
        if (cellText.contains('星期一')) {
          headerRowIndex = i;
          break;
        }
      }
      if (headerRowIndex != null) break;
    }

    if (headerRowIndex == null) {
      throw Exception('未找到课程表表头（星期行）');
    }

    // 解析表头，获取每列对应的星期
    final List<int?> weekdayColumns = [];
    final headerRow = sheet.row(headerRowIndex);

    for (int col = 0; col < headerRow.length; col++) {
      final cellValue = headerRow[col]?.value?.toString() ?? '';
      int? weekday;

      weekdayMap.forEach((key, value) {
        if (cellValue.contains(key)) {
          weekday = value;
        }
      });

      weekdayColumns.add(weekday);
    }

    // 解析课程数据（从表头下一行开始）
    for (int row = headerRowIndex + 1; row < sheet.maxRows; row++) {
      final rowData = sheet.row(row);

      // 第一列是节次和时间，格式如："1\n08:00-08:45"
      final timeSlotCell = rowData[0]?.value?.toString() ?? '';
      if (timeSlotCell.trim().isEmpty) continue;

      // 提取节次编号（第一个数字）
      final sectionMatch = RegExp(r'^(\d+)').firstMatch(timeSlotCell);
      if (sectionMatch == null) continue;

      final sectionNumber = sectionMatch.group(1)!;
      final startTime = timeSlots[sectionNumber];
      if (startTime == null) continue;

      // 遍历每一列（每个星期）
      for (int col = 1; col < rowData.length && col < weekdayColumns.length; col++) {
        final weekday = weekdayColumns[col];
        if (weekday == null) continue;

        final cellValue = rowData[col]?.value?.toString().trim() ?? '';
        if (cellValue.isEmpty) continue;

        // 解析单元格中的课程（可能有多门课）
        final courses = _parseCourseCell(cellValue);

        for (var course in courses) {
          // 检查是否已存在相同课程（避免连续节次重复添加）
          final isDuplicate = todos.any((t) =>
          t.weekday == weekday &&
              t.time?.hour == startTime.hour &&
              t.time?.minute == startTime.minute &&
              t.title.contains(course.name));

          if (!isDuplicate) {
            todos.add(Todo(
              title: '${course.name} ${course.location}',
              done: false,
              weekday: weekday,
              time: startTime,
            ));
          }
        }
      }
    }

    return todos;
  }

  /// 解析单元格中的课程信息
  /// 课程格式：
  /// 课程名
  /// 教师(职称)
  /// 周次
  /// 教室
  /// [节次]
  static List<CourseInfo> _parseCourseCell(String cellValue) {
    final List<CourseInfo> courses = [];

    // 按空行分割多门课程
    final courseBlocks = cellValue.split(RegExp(r'\n\s*\n|\n(?=[^\s])(?=\S+\n)'));

    for (var block in courseBlocks) {
      block = block.trim();
      if (block.isEmpty) continue;

      final lines = block.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isEmpty) continue;

      String courseName = '';
      String location = '';

      // 第一行通常是课程名称
      courseName = lines[0];

      // 查找教室信息（包含"-"的行，如"教学实验综合楼-S114"）
      for (var line in lines) {
        if (line.contains('-') && (line.contains('楼') || line.contains('馆'))) {
          // 提取教学楼和教室
          final locationMatch = RegExp(r'([^-\n]+[-]\s*[A-Za-z0-9]+)').firstMatch(line);
          if (locationMatch != null) {
            location = locationMatch.group(1)!.trim();
            break;
          }
        }
      }

      // 如果没有找到教室，尝试其他格式
      if (location.isEmpty) {
        for (var line in lines) {
          // 匹配"教学楼名-房间号"或"教学楼名房间号"
          final simpleMatch = RegExp(r'([\u4e00-\u9fa5]+[楼馆][\s-]*[A-Za-z0-9]+)').firstMatch(line);
          if (simpleMatch != null) {
            location = simpleMatch.group(1)!.trim();
            break;
          }
        }
      }

      if (courseName.isNotEmpty) {
        courses.add(CourseInfo(
          name: courseName,
          location: location.isNotEmpty ? location : '待定',
          time: TimeOfDay.now(), // 这里会被外层函数替换
          weekday: 1, // 这里会被外层函数替换
        ));
      }
    }

    return courses;
  }

  /// 合并导入的课程到现有待办列表
  /// 会检查重复（相同星期、时间、标题）
  static List<Todo> mergeWithExisting(List<Todo> existing, List<Todo> imported) {
    final result = List<Todo>.from(existing);

    for (var importedTodo in imported) {
      // 检查是否已存在相同的待办
      final isDuplicate = existing.any((todo) =>
      todo.weekday == importedTodo.weekday &&
          todo.time?.hour == importedTodo.time?.hour &&
          todo.time?.minute == importedTodo.time?.minute &&
          todo.title == importedTodo.title);

      if (!isDuplicate) {
        result.add(importedTodo);
      }
    }

    return result;
  }
}