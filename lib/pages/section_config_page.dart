import 'package:flutter/material.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/section_slot.dart';

class SectionConfigPage extends StatefulWidget {
  const SectionConfigPage({super.key});

  @override
  State<SectionConfigPage> createState() => _SectionConfigPageState();
}

class _SectionConfigPageState extends State<SectionConfigPage> {
  final ScheduleRepository _repository = ScheduleRepository();
  List<SectionSlot> _sections = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sections = await _repository.fetchSections();
    if (!mounted) {
      return;
    }
    setState(() {
      _sections = sections;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await _repository.saveSections(_sections);
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<int?> _pickTime(int initialMinutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
    );
    if (picked == null) {
      return null;
    }
    return picked.hour * 60 + picked.minute;
  }

  Future<void> _editSection(SectionSlot slot) async {
    int start = slot.startMinutes;
    int duration = slot.durationMinutes;
    int end = slot.endMinutes;
    final durationController = TextEditingController(text: duration.toString());

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void syncFromDuration() {
              final value = int.tryParse(durationController.text.trim());
              if (value == null || value < 1) {
                return;
              }
              duration = value;
              end = (start + duration).clamp(start + 1, 24 * 60 - 1);
            }

            return AlertDialog(
              title: Text('编辑第${slot.number}节'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('开始时间'),
                    subtitle: Text(_formatMinutes(start)),
                    trailing: const Icon(Icons.schedule),
                    onTap: () async {
                      final picked = await _pickTime(start);
                      if (picked == null) {
                        return;
                      }
                      setDialogState(() {
                        start = picked;
                        end = (start + duration).clamp(start + 1, 24 * 60 - 1);
                      });
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('结束时间'),
                    subtitle: Text(_formatMinutes(end)),
                    trailing: const Icon(Icons.schedule_send),
                    onTap: () async {
                      final picked = await _pickTime(end);
                      if (picked == null) {
                        return;
                      }
                      setDialogState(() {
                        end = picked <= start ? start + 1 : picked;
                        duration = end - start;
                        durationController.text = duration.toString();
                      });
                    },
                  ),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '时长（分钟）',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setDialogState(syncFromDuration);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    syncFromDuration();
                    setState(() {
                      final idx = _sections.indexWhere(
                        (e) => e.number == slot.number,
                      );
                      if (idx >= 0) {
                        _sections[idx] = slot.copyWith(
                          startMinutes: start,
                          endMinutes: end,
                        );
                      }
                    });
                    await _save();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('节次设置')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final slot = _sections[index];
                return Material(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    title: Text('第${slot.number}节'),
                    subtitle: Text(
                      '${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}  ·  ${slot.durationMinutes}分钟',
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _editSection(slot),
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: _sections.length,
            ),
    );
  }
}
