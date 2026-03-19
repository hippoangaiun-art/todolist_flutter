import 'package:flutter/material.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/section_slot.dart';
import 'package:todolist/pages/section_config_page.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ScheduleRepository _repository = ScheduleRepository();
  List<SectionSlot> _sections = const [];

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
    });
  }

  String _formatMinutes(int minutes) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const SizedBox(height: 16),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('节次预览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  if (_sections.isEmpty)
                    const Text('暂无节次')
                  else
                    ..._sections.take(5).map(
                      (slot) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text('第${slot.number}节 ${_formatMinutes(slot.startMinutes)} - ${_formatMinutes(slot.endMinutes)}'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
