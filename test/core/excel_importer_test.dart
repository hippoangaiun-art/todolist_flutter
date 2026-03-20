import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/excel_importer.dart';
import 'package:todolist/models/section_slot.dart';

void main() {
  test('Excel 导入可解析课程为 Course 列表', () async {
    final excel = Excel.createExcel();
    final sheet = excel.tables[excel.tables.keys.first]!;

    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('节次');
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('星期一');
    sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('1');
    sheet.cell(CellIndex.indexByString('B2')).value = TextCellValue('高等数学\n1-18周\n教一-101');

    final bytes = excel.encode()!;
    final sections = [
      const SectionSlot(number: 1, startMinutes: 480, endMinutes: 525),
    ];

    final courses = await CourseExcelImporter.importFromBytes(bytes: bytes, sections: sections);

    expect(courses.isNotEmpty, true);
    expect(courses.first.name, '高等数学');
    expect(courses.first.meetings.first.weekday, 1);
  });
}
