import 'package:flutter/material.dart';
import 'package:todolist/core/theme_mode_notifier.dart';
import 'package:todolist/models/schedule_settings.dart';

class ScheduleSettingsPage extends StatefulWidget {
  final ScheduleSettings initial;

  const ScheduleSettingsPage({
    super.key,
    required this.initial,
  });

  @override
  State<ScheduleSettingsPage> createState() => _ScheduleSettingsPageState();
}

class _ScheduleSettingsPageState extends State<ScheduleSettingsPage> {
  late ScheduleSettings _settings;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _settings = widget.initial;
    _themeMode = parseThemeMode(widget.initial.themeMode);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '未设置';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _pickFirstWeekDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _settings.firstWeekDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _settings = _settings.copyWith(firstWeekDate: DateTime(picked.year, picked.month, picked.day));
    });
  }

  String _modeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return '跟随系统';
      case ThemeMode.light:
        return '浅色';
      case ThemeMode.dark:
        return '深色';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('课表设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              title: const Text('第一周对应日期'),
              subtitle: Text(_formatDate(_settings.firstWeekDate)),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickFirstWeekDate,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _settings = _settings.copyWith(clearFirstWeekDate: true);
              });
            },
            icon: const Icon(Icons.clear),
            label: const Text('清空第一周日期'),
          ),
          const SizedBox(height: 16),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                ListTile(
                  title: const Text('主题模式'),
                  subtitle: Text(_modeLabel(_themeMode)),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: _themeMode,
                  title: const Text('跟随系统'),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _themeMode = value;
                    });
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: _themeMode,
                  title: const Text('浅色模式'),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _themeMode = value;
                    });
                  },
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: _themeMode,
                  title: const Text('深色模式'),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _themeMode = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(
                _settings.copyWith(themeMode: encodeThemeMode(_themeMode)),
              );
            },
            child: const Text('保存设置'),
          ),
        ],
      ),
    );
  }
}
