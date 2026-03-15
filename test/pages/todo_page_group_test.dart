import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todolist/pages/todo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('点击未完成分组标题后可折叠列表', (tester) async {
    SharedPreferences.setMockInitialValues({
      'todolist': '[{"title":"测试待办","done":false}]',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: TodoPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);

    await tester.tap(find.text('未完成'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsNothing);
    expect(find.byIcon(Icons.expand_more), findsNWidgets(2));
  });
}
