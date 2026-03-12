import 'package:permission_handler/permission_handler.dart';

// 检查并请求存储权限
// 返回 true 表示已授权，false 表示未授权
Future<bool> checkAndRequestStoragePermission() async {
  PermissionStatus status;
  if (await Permission.storage.isGranted) {
    return true;
  }

  status = await Permission.storage.request();

  if (status.isGranted) {
    return true;
  } else if (status.isPermanentlyDenied) {
    openAppSettings();
    return false;
  }

  return false;
}
