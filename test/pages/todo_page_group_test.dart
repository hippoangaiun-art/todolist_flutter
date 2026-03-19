import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/pages/todo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('待办页可正常渲染并显示新增入口', (tester) async {
    SharedPreferences.setMockInitialValues({
      'todos_v2': '[]',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: TodoPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('新增待办'), findsOneWidget);
    expect(find.text('这一天暂无待办'), findsOneWidget);
  });
}
