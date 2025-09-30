import 'package:permission_handler/permission_handler.dart';
import 'package:todolist/core/const.dart';

Future<bool> checkStoragePermission() async {
  // 检查状态
  var status = await Permission.storage.status;

  if (status.isDenied) {
    status = await Permission.storage.request();
  }

  if (status.isPermanentlyDenied) {
    // 用户永久拒绝，需要跳转设置
    openAppSettings();
    return false;
  }

  return status.isGranted;
}
