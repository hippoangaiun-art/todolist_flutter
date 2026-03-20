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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sections = await _repository.fetchSections();
    final courses = await _repository.fetchCourses();
    final settings = await _repository.fetchSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _sections = sections;
      _courses = courses;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _saveCourses() async {
    await _repository.saveCourses(_courses);
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
    setState(() {
      _settings = next;
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
        _courses = [..._courses, ...imported];
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

  Future<void> _deleteCourse(Course course) async {
    setState(() {
      _courses = _courses.where((e) => e.id != course.id).toList();
    });
    await _saveCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
        actions: [
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune),
            tooltip: '课表设置',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    title: const Text('第一周对应日期'),
                    subtitle: Text(_formatDate(_settings.firstWeekDate)),
                    trailing: const Icon(Icons.edit_calendar),
                    onTap: _openSettings,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  child: ListTile(
                    title: const Text('节次设置'),
                    subtitle: Text(_sections.isEmpty ? '尚未配置节次' : '已配置 ${_sections.length} 节，点击编辑开始/结束/时长'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SectionConfigPage()),
                      );
                      await _load();
                    },
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _importFromExcel,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('从 Excel 导入课表'),
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
                if (_courses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('暂无课程，点击右上角新增'),
                  )
                else
                  ..._courses.map(
                    (course) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
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
                  ),
              ],
            ),
    );
  }
}
