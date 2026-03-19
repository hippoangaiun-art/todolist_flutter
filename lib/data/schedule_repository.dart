import 'dart:convert';

import 'package:todolist/core/const.dart';
import 'package:todolist/models/section_slot.dart';

class ScheduleRepository {
  Future<List<SectionSlot>> fetchSections() async {
    final raw = await Const.scheduleSections.value;
    if (raw.trim().isEmpty || raw.trim() == '[]') {
      return defaultSections();
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SectionSlot.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
  }

  Future<void> saveSections(List<SectionSlot> sections) async {
    final payload = jsonEncode(sections.map((e) => e.toJson()).toList());
    await Const.scheduleSections.setValue(payload);
  }

  List<SectionSlot> defaultSections() {
    final starts = [
      8 * 60,
      8 * 60 + 50,
      9 * 60 + 50,
      10 * 60 + 40,
      11 * 60 + 30,
      13 * 60,
      13 * 60 + 50,
      14 * 60 + 45,
      15 * 60 + 40,
      16 * 60 + 35,
      17 * 60 + 25,
      18 * 60 + 30,
    ];

    return List.generate(starts.length, (index) {
      final start = starts[index];
      final end = start + 45;
      return SectionSlot(number: index + 1, startMinutes: start, endMinutes: end);
    });
  }
}
