import 'package:package_info_plus/package_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:todolist/utils/preferences.dart';

final logger = Logger();

Future<int> getAppVersionCode() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return int.parse(packageInfo.version); // 构建号（如 12）
}



Future<void> checkUpdate() async {
  //TODO 写检查更新
}

class Todo {
  final String title;
  final bool done;
  final DateTime? ddl;

  Todo({
    required this.title,
    this.done = false,
    this.ddl,
  });
}

class Const {
  static final githubUrl = "https://github.com/hippoangaiun-art/todolist_flutter";
  static final todoLists = PrefField<String>("todolist", """
  [
  {
    "name": "Welcome.",
    "done": false,
    "ddl": "2077-07-07 23:59:59"
  }
]
  """);

  static final appName = "ToDo List";
}
