import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:todolist/utils/preferences.dart';

final logger = Logger();

Future<int> getAppVersionCode() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return int.parse(packageInfo.version);
}

Future<void> checkUpdate() async {}

class Const {
  static final githubUrl =
      'https://github.com/hippoangaiun-art/todolist_flutter';

  static final todoListV2 = PrefField<String>('todos_v2', '[]');
  static final scheduleCourses = PrefField<String>('schedule_courses_v1', '[]');
  static final scheduleSections = PrefField<String>(
    'schedule_sections_v1',
    '[]',
  );
  static final scheduleSettings = PrefField<String>(
    'schedule_settings_v1',
    '{}',
  );

  static final appName = 'ToDo List';
}
