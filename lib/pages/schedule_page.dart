import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:todolist/core/excel_importer.dart';
import 'package:todolist/core/schedule_rules.dart';
import 'package:todolist/core/theme_mode_notifier.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/course.dart';
import 'package:todolist/models/schedule_settings.dart';
import 'package:todolist/models/section_slot.dart';
import 'package:todolist/pages/course_editor_page.dart';
import 'package:todolist/pages/section_config_page.dart';
import 'package:todolist/utils/permission.dart';
import 'package:todolist/widgets/gradient_background.dart';
import 'package:todolist/widgets/surface_style.dart';

class SchedulePage extends StatefulWidget {
  final bool isActive;

  const SchedulePage({super.key, required this.isActive});

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

  @override
  void didUpdateWidget(covariant SchedulePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _load();
    }
  }

  Future<void> _load() async {
    final sections = await _repository.fetchSections();
    final courses = await _repository.fetchCourses();
    final settings = await _repository.fetchSettings();
    if (!mounted) {
      return;
    }
    final currentWeek = ScheduleRules.resolveWeekFromDate(
      DateTime.now(),
      settings.firstWeekDate,
    );
    setState(() {
      _sections = sections;
      _courses = courses;
      _settings = settings;
      _selectedWeek = currentWeek;
      _loading = false;
    });
    appThemeModeNotifier.value = parseThemeMode(settings.themeMode);
  }

  Future<void> _saveCourses() async {
    await _repository.saveCourses(_courses);
  }

  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${labels[weekday - 1]}';
  }

  String _meetingText(CourseMeeting meeting) {
    return '${_weekdayLabel(meeting.weekday)} ${_meetingTimeText(meeting)} ${meeting.weekStart}-${meeting.weekEnd}周';
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
        builder: (_) => CourseEditorPage(sections: _sections, initial: course),
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
    final next = _settings.copyWith(
      firstWeekDate: DateTime(picked.year, picked.month, picked.day),
    );
    setState(() {
      _settings = next;
      _selectedWeek = ScheduleRules.resolveWeekFromDate(
        DateTime.now(),
        next.firstWeekDate,
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先授予存储权限')));
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
        SnackBar(
          content: Text(
            '已导入 ${imported.length} 门课程（第一周：${_formatDate(firstWeekDate)}）',
          ),
        ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先设置第一周日期再进行日期定位')));
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
      _selectedWeek = ScheduleRules.resolveWeekFromDate(
        picked,
        _settings.firstWeekDate,
      );
    });
  }

  void _goToCurrentWeek() {
    setState(() {
      _selectedWeek = ScheduleRules.resolveWeekFromDate(
        DateTime.now(),
        _settings.firstWeekDate,
      );
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
    return ScheduleRules.weekdayDateInWeek(
      weekday: weekday,
      selectedWeek: _selectedWeek,
      firstWeekDate: firstWeekDate,
    );
  }

  List<_ScheduleEntry> _entriesForWeekday(int weekday) {
    final entries = <_ScheduleEntry>[];
    for (final course in _courses) {
      for (final meeting in course.meetings) {
        if (meeting.weekday != weekday) {
          continue;
        }
        if (!ScheduleRules.isMeetingVisible(meeting, _selectedWeek)) {
          continue;
        }
        entries.add(_ScheduleEntry(course: course, meeting: meeting));
      }
    }
    entries.sort(
      (a, b) => a.meeting.startSection.compareTo(b.meeting.startSection),
    );
    return entries;
  }

  String _formatMinutes(int minutes) {
    final hour = (minutes ~/ 60).toString().padLeft(2, '0');
    final minute = (minutes % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  SectionSlot? _findSection(int number) {
    for (final section in _sections) {
      if (section.number == number) {
        return section;
      }
    }
    return null;
  }

  String _meetingTimeText(CourseMeeting meeting) {
    final start = _findSection(meeting.startSection);
    final end = _findSection(meeting.endSection);
    if (start == null || end == null) {
      return '时间未配置';
    }
    return '${_formatMinutes(start.startMinutes)}-${_formatMinutes(end.endMinutes)}';
  }

  Color _softSurface(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainerHigh;
    }
    return Colors.white.withValues(alpha: 0.86);
  }

  Color _softSurfaceStrong(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainer;
    }
    return Colors.white.withValues(alpha: 0.92);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: '节次设置',
            onPressed: _loading
                ? null
                : () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SectionConfigPage(),
                      ),
                    );
                    await _load();
                  },
            icon: const Icon(Icons.schedule),
          ),
        ],
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _softSurface(context),
                      borderRadius: BorderRadius.circular(16),
                      border: SurfaceStyle.cardBorder(context),
                      boxShadow: SurfaceStyle.cardShadow(context),
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
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
                              color: _softSurface(context),
                              border: SurfaceStyle.cardBorder(context),
                              boxShadow: SurfaceStyle.cardShadow(context),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _weekdayLabel(weekday),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: entries.isEmpty
                                        ? const Center(child: Text('无课程'))
                                        : ListView.separated(
                                            itemCount: entries.length,
                                            separatorBuilder: (_, _) =>
                                                const SizedBox(height: 8),
                                            itemBuilder: (context, i) {
                                              final entry = entries[i];
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .secondaryContainer,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      entry.course.name,
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _meetingTimeText(
                                                        entry.meeting,
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    if (entry
                                                        .course
                                                        .classroom
                                                        .isNotEmpty)
                                                      Text(
                                                        entry.course.classroom,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
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
                      const Text(
                        '课程列表',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                                      color: Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: SurfaceStyle.cardBorder(
                                            context,
                                          ),
                                          boxShadow: SurfaceStyle.cardShadow(
                                            context,
                                          ),
                                        ),
                                        child: Material(
                                          color: _softSurfaceStrong(context),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            onTap: () =>
                                                _openEditor(course: course),
                                            child: Padding(
                                              padding: const EdgeInsets.all(14),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          course.name,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                              ),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        onPressed: () =>
                                                            _deleteCourse(
                                                              course,
                                                            ),
                                                        icon: const Icon(
                                                          Icons.delete_outline,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (course
                                                          .classroom
                                                          .isNotEmpty ||
                                                      course
                                                          .location
                                                          .isNotEmpty)
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 6,
                                                          ),
                                                      child: Text(
                                                        '${course.classroom}  ${course.location}'
                                                            .trim(),
                                                      ),
                                                    ),
                                                  ...course.meetings.map(
                                                    (m) => Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                            bottom: 4,
                                                          ),
                                                      child: Text(
                                                        _meetingText(m),
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
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
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              heroTag: 'schedule_import_fab',
              onPressed: _importFromExcel,
              icon: const Icon(Icons.upload_file),
              label: const Text('导入课表'),
            ),
    );
  }
}

class _ScheduleEntry {
  final Course course;
  final CourseMeeting meeting;

  const _ScheduleEntry({required this.course, required this.meeting});
}
