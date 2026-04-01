import 'package:flutter/material.dart';
import 'package:todolist/pages/schedule_page.dart';
import 'package:todolist/pages/settings_page.dart';
import 'package:todolist/pages/todo.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HeroMode(enabled: _selectedIndex == 0, child: const TodoPage()),
      HeroMode(
        enabled: _selectedIndex == 1,
        child: SchedulePage(isActive: _selectedIndex == 1),
      ),
      HeroMode(
        enabled: _selectedIndex == 2,
        child: SettingsPage(isActive: _selectedIndex == 2),
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: '待办',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: '课表',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
        ],
      ),
    );
  }
}
