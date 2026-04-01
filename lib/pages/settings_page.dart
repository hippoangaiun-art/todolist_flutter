import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/theme_mode_notifier.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/schedule_settings.dart';
import 'package:todolist/widgets/gradient_background.dart';
import 'package:todolist/widgets/surface_style.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  final bool isActive;

  const SettingsPage({super.key, required this.isActive});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ScheduleRepository _repository = ScheduleRepository();
  ScheduleSettings _settings = const ScheduleSettings(firstWeekDate: null);
  ThemeMode _themeMode = ThemeMode.system;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadSettings();
    }
  }

  Future<void> _loadSettings() async {
    final settings = await _repository.fetchSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _settings = settings;
      _themeMode = parseThemeMode(settings.themeMode);
      _loading = false;
    });
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Color _surfaceColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainerHigh;
    }
    return Colors.white.withValues(alpha: 0.9);
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '未设置';
    }
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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

  Future<void> _applySettings({
    ScheduleSettings? settings,
    ThemeMode? themeMode,
  }) async {
    final nextThemeMode = themeMode ?? _themeMode;
    final nextSettings = (settings ?? _settings).copyWith(
      themeMode: encodeThemeMode(nextThemeMode),
    );
    if (mounted) {
      setState(() {
        _settings = nextSettings;
        _themeMode = nextThemeMode;
      });
    }
    await _repository.saveSettings(nextSettings);
    appThemeModeNotifier.value = nextThemeMode;
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
    await _applySettings(
      settings: _settings.copyWith(
        firstWeekDate: DateTime(picked.year, picked.month, picked.day),
      ),
    );
  }

  Future<void> _clearFirstWeekDate() async {
    await _applySettings(
      settings: _settings.copyWith(clearFirstWeekDate: true),
    );
  }

  Future<void> _showThemeSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: RadioGroup<ThemeMode>(
                groupValue: _themeMode,
                onChanged: (value) async {
                  if (value == null) {
                    return;
                  }
                  setModalState(() {});
                  await _applySettings(themeMode: value);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '主题模式',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      title: Text('跟随系统'),
                    ),
                    const RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      title: Text('浅色模式'),
                    ),
                    const RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      title: Text('深色模式'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: SurfaceStyle.cardBorder(context),
        boxShadow: SurfaceStyle.cardShadow(context),
      ),
      child: Material(
        color: _surfaceColor(context),
        borderRadius: BorderRadius.circular(18),
        child: child,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                children: [
                  _buildSectionTitle('课表'),
                  _buildCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.calendar_month_outlined),
                          title: const Text('第一周对应日期'),
                          subtitle: Text(_formatDate(_settings.firstWeekDate)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _pickFirstWeekDate,
                        ),
                        _buildDivider(),
                        ListTile(
                          leading: const Icon(Icons.restart_alt_outlined),
                          title: const Text('清空第一周日期'),
                          subtitle: const Text('定位周次时将不再自动换算'),
                          enabled: _settings.firstWeekDate != null,
                          onTap: _settings.firstWeekDate == null
                              ? null
                              : _clearFirstWeekDate,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('外观'),
                  _buildCard(
                    child: ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text('主题模式'),
                      subtitle: Text(_modeLabel(_themeMode)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showThemeSheet,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('应用'),
                  _buildCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.code),
                          title: const Text('BUPT ToDo List'),
                          subtitle: const Text('访问GitHub主页'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _launchURL(Const.githubUrl),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
