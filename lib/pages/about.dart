import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/theme_mode_notifier.dart';
import 'package:todolist/data/schedule_repository.dart';
import 'package:todolist/models/schedule_settings.dart';
import 'package:todolist/widgets/gradient_background.dart';
import 'package:todolist/widgets/surface_style.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  final bool isActive;

  const AboutPage({super.key, required this.isActive});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
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
  void didUpdateWidget(covariant AboutPage oldWidget) {
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

  Color _softSurface(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainerHigh;
    }
    return Colors.white.withValues(alpha: 0.88);
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
    _applySettings(
      settings: _settings.copyWith(
        firstWeekDate: DateTime(picked.year, picked.month, picked.day),
      ),
    );
  }

  void _clearFirstWeekDate() {
    _applySettings(
      settings: _settings.copyWith(clearFirstWeekDate: true),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
        backgroundColor: Colors.transparent,
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: _softSurface(context),
                          borderRadius: BorderRadius.circular(20),
                          border: SurfaceStyle.cardBorder(context),
                          boxShadow: SurfaceStyle.cardShadow(context),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '课表与主题设置',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.calendar_month),
                                  title: const Text('第一周对应日期'),
                                  subtitle: Text(_formatDate(_settings.firstWeekDate)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _pickFirstWeekDate,
                                ),
                              ),
                              Row(
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _clearFirstWeekDate,
                                    icon: const Icon(Icons.clear),
                                    label: const Text('清空日期'),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '当前主题：${_modeLabel(_themeMode)}',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RadioGroup<ThemeMode>(
                                groupValue: _themeMode,
                                onChanged: (value) async {
                                  if (value == null) {
                                    return;
                                  }
                                  await _applySettings(themeMode: value);
                                },
                                child: const Column(
                                  children: [
                                    RadioListTile<ThemeMode>(
                                      value: ThemeMode.system,
                                      title: Text('跟随系统'),
                                    ),
                                    RadioListTile<ThemeMode>(
                                      value: ThemeMode.light,
                                      title: Text('浅色模式'),
                                    ),
                                    RadioListTile<ThemeMode>(
                                      value: ThemeMode.dark,
                                      title: Text('深色模式'),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _softSurface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: SurfaceStyle.cardBorder(context),
                          boxShadow: SurfaceStyle.cardShadow(context),
                        ),
                        child: Column(
                          children: [
                            SvgPicture.asset(
                              'assets/icon/splash.svg',
                              width: 120,
                              height: 120,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'BUPT ToDo List',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '课表与待办一体化管理',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: SurfaceStyle.cardBorder(context),
                          boxShadow: SurfaceStyle.cardShadow(context),
                        ),
                        child: Material(
                          color: _softSurface(context),
                          borderRadius: BorderRadius.circular(16),
                          child: ListTile(
                            leading: const Icon(Icons.code),
                            title: const Text('GitHub 项目主页'),
                            subtitle: Text(Const.githubUrl),
                            trailing: const Icon(Icons.open_in_new),
                            onTap: () => _launchURL(Const.githubUrl),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
