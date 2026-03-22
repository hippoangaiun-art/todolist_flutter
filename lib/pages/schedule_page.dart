import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:todolist/core/excel_importer.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/course.dart';
import 'package:todolist/models/schedule_settings.dart';
import 'package:todolist/models/section_slot.dart';
import 'package:todolist/pages/course_editor_page.dart';
import 'package:todolist/pages/schedule_settings_page.dart';
import 'package:todolist/pages/section_config_page.dart';
import 'package:todolist/utils/permission.dart';
import 'package:todolist/widgets/gradient_background.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ScheduleRepository _repository = ScheduleRepository();
  List<SectionSlot> _sections = const [];
  List<Course> _courses = const [];
  ScheduleSettings _settings = const ScheduleSettings(firstWeekDate: null);
  bool _loading = true;
  int _selectedWeek = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  Future<void> _load() async {
    final sections = await _repository.fetchSections();
    final courses = await _repository.fetchCourses();
    final settings = await _repository.fetchSettings();
    if (!mounted) {
      return;
    }
    final currentWeek = _resolveWeekFromDate(DateTime.now(), settings);
    setState(() {
      _sections = sections;
      _courses = courses;
      _settings = settings;
      _selectedWeek = currentWeek;
      _loading = false;
    });
  }

  Future<void> _saveCourses() async {
    await _repository.saveCourses(_courses);
  }

  int _resolveWeekFromDate(DateTime date, ScheduleSettings settings) {
    if (settings.firstWeekDate == null) {
      return 1;
    }
    final diff = _normalize(date).difference(_normalize(settings.firstWeekDate!)).inDays;
    if (diff < 0) {
      return 1;
    }
    return diff ~/ 7 + 1;
  }

  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${labels[weekday - 1]}';
  }

  String _meetingText(CourseMeeting meeting) {
    return '${_weekdayLabel(meeting.weekday)} 第${meeting.startSection}-${meeting.endSection}节 ${meeting.weekStart}-${meeting.weekEnd}周';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '未设置';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _openEditor({Course? course}) async {
    final result = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => CourseEditorPage(
          sections: _sections,
          initial: course,
        ),
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      final idx = _courses.indexWhere((e) => e.id == result.id);
      if (idx >= 0) {
        _courses[idx] = result;
      } else {
        _courses = [result, ..._courses];
      }
    });
    await _saveCourses();
  }

  Future<void> _openSettings() async {
    final next = await Navigator.of(context).push<ScheduleSettings>(
      MaterialPageRoute(
        builder: (_) => ScheduleSettingsPage(initial: _settings),
      ),
    );
    if (next == null) {
      return;
    }
    final week = _resolveWeekFromDate(DateTime.now(), next);
    setState(() {
      _settings = next;
      _selectedWeek = week;
    });
    await _repository.saveSettings(next);
  }

  Future<DateTime?> _ensureFirstWeekDate() async {
    if (_settings.firstWeekDate != null) {
      return _settings.firstWeekDate;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      helpText: '导入前设置第一周日期',
    );
    if (picked == null) {
      return null;
    }
    final next = _settings.copyWith(firstWeekDate: DateTime(picked.year, picked.month, picked.day));
    setState(() {
      _settings = next;
      _selectedWeek = _resolveWeekFromDate(DateTime.now(), next);
    });
    await _repository.saveSettings(next);
    return next.firstWeekDate;
  }

  Future<void> _importFromExcel() async {
    final firstWeekDate = await _ensureFirstWeekDate();
    if (firstWeekDate == null) {
      return;
    }

    final granted = await checkStoragePermission();
    if (!granted) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先授予存储权限')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result == null || result.files.single.path == null) {
      return;
    }

    if (!mounted) {
      return;
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final imported = await CourseExcelImporter.importFromBytes(
        bytes: bytes,
        sections: _sections,
      );

      setState(() {
        _courses = CourseExcelImporter.mergeWithExisting(_courses, imported);
      });
      await _saveCourses();

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已导入 ${imported.length} 门课程（第一周：${_formatDate(firstWeekDate)}）')),
      );
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (!mounted) {
        return;
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('导入失败'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _goToDate() async {
    if (_settings.firstWeekDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先设置第一周日期再进行日期定位')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      helpText: '定位到对应周次',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedWeek = _resolveWeekFromDate(picked, _settings);
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeek = _resolveWeekFromDate(DateTime.now(), _settings);
    });
  }

  Future<void> _deleteCourse(Course course) async {
    setState(() {
      _courses = _courses.where((e) => e.id != course.id).toList();
    });
    await _saveCourses();
  }

  DateTime? _weekdayDateInWeek(int weekday) {
    final firstWeekDate = _settings.firstWeekDate;
    if (firstWeekDate == null) {
      return null;
    }
    final start = _normalize(firstWeekDate).add(Duration(days: (_selectedWeek - 1) * 7));
    return start.add(Duration(days: weekday - 1));
  }

  List<_ScheduleEntry> _entriesForWeekday(int weekday) {
    final entries = <_ScheduleEntry>[];
    for (final course in _courses) {
      for (final meeting in course.meetings) {
        if (meeting.weekday != weekday) {
          continue;
        }
        if (_selectedWeek < meeting.weekStart || _selectedWeek > meeting.weekEnd) {
          continue;
        }
        entries.add(_ScheduleEntry(course: course, meeting: meeting));
      }
    }
    entries.sort((a, b) => a.meeting.startSection.compareTo(b.meeting.startSection));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
            tooltip: '课表设置',
          ),
        ],
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          icon: Icons.edit_calendar,
                          title: '第一周日期',
                          subtitle: _formatDate(_settings.firstWeekDate),
                          onTap: _openSettings,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionCard(
                          icon: Icons.upload_file,
                          title: '导入课表',
                          subtitle: 'Excel 文件',
                          onTap: _importFromExcel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _actionCard(
                    icon: Icons.schedule,
                    title: '节次设置',
                    subtitle: _sections.isEmpty ? '尚未配置节次' : '已配置 ${_sections.length} 节，点击编辑',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SectionConfigPage()),
                      );
                      await _load();
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedWeek = (_selectedWeek - 1).clamp(1, 30);
                            });
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        Expanded(
                          child: Text(
                            '第 $_selectedWeek 周',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedWeek = (_selectedWeek + 1).clamp(1, 30);
                            });
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToCurrentWeek,
                          icon: const Icon(Icons.my_location),
                          label: const Text('回到本周'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _goToDate,
                          icon: const Icon(Icons.search),
                          label: const Text('日期定位'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 420,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(7, (index) {
                          final weekday = index + 1;
                          final date = _weekdayDateInWeek(weekday);
                          final entries = _entriesForWeekday(weekday);
                          return Container(
                            width: 190,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.white.withValues(alpha: 0.85),
                              boxShadow: const [
                                BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 6)),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_weekdayLabel(weekday), style: const TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: entries.isEmpty
                                        ? const Center(child: Text('无课程'))
                                        : ListView.separated(
                                            itemCount: entries.length,
                                            separatorBuilder: (_, _) => const SizedBox(height: 8),
                                            itemBuilder: (context, i) {
                                              final entry = entries[i];
                                              return Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  color: Theme.of(context).colorScheme.secondaryContainer,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.course.name,
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text('第${entry.meeting.startSection}-${entry.meeting.endSection}节', style: const TextStyle(fontSize: 12)),
                                                    if (entry.course.classroom.isNotEmpty)
                                                      Text(entry.course.classroom, style: const TextStyle(fontSize: 12)),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('课程列表', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      FilledButton.tonalIcon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add),
                        label: const Text('新增课程'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _courses.isEmpty
                        ? const Padding(
                            key: ValueKey('course-empty'),
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(child: Text('暂无课程，点击右上角新增')),
                          )
                        : Column(
                            key: const ValueKey('course-list'),
                            children: _courses
                                .map(
                                  (course) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Material(
                                      color: Colors.white.withValues(alpha: 0.88),
                                      borderRadius: BorderRadius.circular(16),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () => _openEditor(course: course),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      course.name,
                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () => _deleteCourse(course),
                                                    icon: const Icon(Icons.delete_outline),
                                                  ),
                                                ],
                                              ),
                                              if (course.classroom.isNotEmpty || course.location.isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 6),
                                                  child: Text('${course.classroom}  ${course.location}'.trim()),
                                                ),
                                              ...course.meetings.map((m) => Padding(
                                                    padding: const EdgeInsets.only(bottom: 4),
                                                    child: Text(_meetingText(m), style: const TextStyle(fontSize: 13)),
                                                  )),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: 0.86),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleEntry {
  final Course course;
  final CourseMeeting meeting;

  const _ScheduleEntry({
    required this.course,
    required this.meeting,
  });
}
