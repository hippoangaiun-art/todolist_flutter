import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todolist/core/theme_mode_notifier.dart';

void main() {
  test('主题字符串与 ThemeMode 可互转', () {
    expect(parseThemeMode('system'), ThemeMode.system);
    expect(parseThemeMode('light'), ThemeMode.light);
    expect(parseThemeMode('dark'), ThemeMode.dark);

    expect(encodeThemeMode(ThemeMode.system), 'system');
    expect(encodeThemeMode(ThemeMode.light), 'light');
    expect(encodeThemeMode(ThemeMode.dark), 'dark');
  });
}
