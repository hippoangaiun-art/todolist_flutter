import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/pages/app_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('底部三Tab可切换到课表页', (tester) async {
    SharedPreferences.setMockInitialValues({
      'todos_v2': '[]',
      'schedule_courses_v1': '[]',
      'schedule_sections_v1': '[]',
      'schedule_settings_v1': '{}',
    });

    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pumpAndSettle();

    expect(find.text('待办'), findsOneWidget);
    expect(find.text('课表'), findsOneWidget);
    expect(find.text('关于'), findsOneWidget);

    await tester.tap(find.text('课表'));
    await tester.pumpAndSettle();

    expect(find.text('导入课表'), findsOneWidget);
  });
}
