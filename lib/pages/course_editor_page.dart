import 'package:flutter/material.dart';
import 'package:todolist/models/course.dart';
import 'package:todolist/models/section_slot.dart';

class CourseEditorPage extends StatefulWidget {
  final Course? initial;
  final List<SectionSlot> sections;

  const CourseEditorPage({super.key, required this.sections, this.initial});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _classroomController;
  late final TextEditingController _locationController;
  late List<CourseMeeting> _meetings;
  bool _meetingError = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    _classroomController = TextEditingController(
      text: widget.initial?.classroom ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initial?.location ?? '',
    );
    _meetings = [...widget.initial?.meetings ?? const <CourseMeeting>[]];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _classroomController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<int> get _sectionNumbers {
    if (widget.sections.isEmpty) {
      return List.generate(12, (index) => index + 1);
    }
    return widget.sections.map((e) => e.number).toList()..sort();
  }

  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${labels[weekday - 1]}';
  }

  Future<void> _editMeeting({CourseMeeting? meeting, int? index}) async {
    int selectedWeekday = meeting?.weekday ?? 1;
    final sectionNumbers = _sectionNumbers;
    int startSection = meeting?.startSection ?? sectionNumbers.first;
    int endSection = meeting?.endSection ?? sectionNumbers.first;
    final weekStartController = TextEditingController(
      text: '${meeting?.weekStart ?? 1}',
    );
    final weekEndController = TextEditingController(
      text: '${meeting?.weekEnd ?? 18}',
    );
    String? error;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(index == null ? '新增上课时段' : '编辑上课时段'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedWeekday,
                      decoration: const InputDecoration(labelText: '星期'),
                      items: List.generate(7, (i) {
                        final weekday = i + 1;
                        return DropdownMenuItem(
                          value: weekday,
                          child: Text(_weekdayLabel(weekday)),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedWeekday = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: startSection,
                            decoration: const InputDecoration(
                              labelText: '起始节次',
                            ),
                            items: sectionNumbers
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('第${n}节'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setDialogState(() {
                                startSection = value;
                                if (endSection < startSection) {
                                  endSection = startSection;
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: endSection,
                            decoration: const InputDecoration(
                              labelText: '结束节次',
                            ),
                            items: sectionNumbers
                                .map(
                                  (n) => DropdownMenuItem(
                                    value: n,
                                    child: Text('第${n}节'),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              setDialogState(() {
                                endSection = value;
                                if (endSection < startSection) {
                                  startSection = endSection;
                                }
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: weekStartController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '起始周'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: weekEndController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '结束周'),
                          ),
                        ),
                      ],
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    final weekStart = int.tryParse(
                      weekStartController.text.trim(),
                    );
                    final weekEnd = int.tryParse(weekEndController.text.trim());
                    if (weekStart == null ||
                        weekEnd == null ||
                        weekStart < 1 ||
                        weekEnd < weekStart) {
                      setDialogState(() {
                        error = '周次范围不合法';
                      });
                      return;
                    }

                    final value = CourseMeeting(
                      weekday: selectedWeekday,
                      startSection: startSection,
                      endSection: endSection,
                      weekStart: weekStart,
                      weekEnd: weekEnd,
                    );

                    setState(() {
                      if (index == null) {
                        _meetings.add(value);
                      } else {
                        _meetings[index] = value;
                      }
                      _meetingError = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _save() {
    final valid = _formKey.currentState?.validate() ?? false;
    setState(() {
      _meetingError = _meetings.isEmpty;
    });
    if (!valid || _meetingError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请完成必填信息后再保存')));
      return;
    }

    final course = Course(
      id:
          widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      classroom: _classroomController.text.trim(),
      location: _locationController.text.trim(),
      meetings: [..._meetings],
    );

    Navigator.of(context).pop(course);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '新增课程' : '编辑课程'),
        actions: [TextButton(onPressed: _save, child: const Text('保存'))],
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '课程名称',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '课程名称不能为空';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _classroomController,
              decoration: const InputDecoration(
                labelText: '教室',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: '上课地点',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '上课时段',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _editMeeting(),
                  icon: const Icon(Icons.add),
                  label: const Text('新增时段'),
                ),
              ],
            ),
            if (_meetingError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '至少需要一个上课时段',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 10),
            if (_meetings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('暂无上课时段'),
              )
            else
              ..._meetings.asMap().entries.map((entry) {
                final index = entry.key;
                final meeting = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    borderRadius: BorderRadius.circular(14),
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: ListTile(
                      title: Text(
                        '${_weekdayLabel(meeting.weekday)} 第${meeting.startSection}-${meeting.endSection}节',
                      ),
                      subtitle: Text(
                        '${meeting.weekStart}-${meeting.weekEnd}周',
                      ),
                      onTap: () => _editMeeting(meeting: meeting, index: index),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            _meetings.removeAt(index);
                            _meetingError = _meetings.isEmpty;
                          });
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
