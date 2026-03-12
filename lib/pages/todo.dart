import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/storage.dart';
import 'dart:async';

import 'package:todolist/pages/about.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

// 需要 vsync 给 AnimatedSize 使用
class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Todo>> _futureTodos;

  // 分组展开状态
  bool _incompleteExpanded = true;
  bool _completedExpanded = false;

  @override
  void initState() {
    super.initState();
    _futureTodos = fetchTodos();
  }

  // 现在传入的是全部 todos（master list），并在 master list 中更新
  void _toggleDone(Todo todo, List<Todo> allTodos) {
    setState(() {
      final index = allTodos.indexOf(todo);
      if (index >= 0) {
        allTodos[index] = Todo(
          title: todo.title,
          done: !todo.done,
          ddl: todo.ddl,
        );
      }
    });

    saveTodos(allTodos); // 点击后立即保存
  }

  String _formatDdl(DateTime? ddl) {
    if (ddl == null) return "";
    return "截止: "
        "${ddl.year.toString().padLeft(4, '0')}-"
        "${ddl.month.toString().padLeft(2, '0')}-"
        "${ddl.day.toString().padLeft(2, '0')} "
        "${ddl.hour.toString().padLeft(2, '0')}:"
        "${ddl.minute.toString().padLeft(2, '0')}:"
        "${ddl.second.toString().padLeft(2, '0')}";
  }

  Future<void> _showTodoDialog(List<Todo> todos, {Todo? todo}) async {
    final isEditing = todo != null;
    final _titleController = TextEditingController(text: todo?.title ?? "");
    DateTime? selectedDate = todo?.ddl;
    TimeOfDay? selectedTime = todo?.ddl != null
        ? TimeOfDay(hour: todo!.ddl!.hour, minute: todo.ddl!.minute)
        : null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formatDdl() {
              if (selectedDate == null && selectedTime == null) return "未选择";
              final dateStr = selectedDate != null
                  ? "${selectedDate!.year.toString().padLeft(4, '0')}-"
                        "${selectedDate!.month.toString().padLeft(2, '0')}-"
                        "${selectedDate!.day.toString().padLeft(2, '0')}"
                  : "";
              final timeStr = selectedTime != null
                  ? "${selectedTime!.hour.toString().padLeft(2, '0')}:"
                        "${selectedTime!.minute.toString().padLeft(2, '0')}:00"
                  : "";
              if (dateStr.isNotEmpty && timeStr.isNotEmpty)
                return "$dateStr $timeStr";
              return dateStr.isNotEmpty ? dateStr : timeStr;
            }

            return AlertDialog(
              title: Text(isEditing ? "编辑待办" : "添加待办"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "名称",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text("截止时间:"),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              formatDdl(),
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final now = DateTime.now();
                              final pickedDate = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? now,
                                firstDate: now,
                                lastDate: DateTime(2100),
                              );
                              if (pickedDate != null) {
                                setDialogState(() {
                                  selectedDate = pickedDate;
                                });
                              }
                            },
                            child: const Text("选择日期"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              final pickedTime = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (pickedTime != null) {
                                setDialogState(() {
                                  selectedTime = pickedTime;
                                });
                              }
                            },
                            child: const Text("选择时间"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("取消"),
                ),
                TextButton(
                  onPressed: () {
                    final title = _titleController.text.trim();
                    if (title.isEmpty) return;

                    DateTime? ddl;
                    if (selectedDate != null) {
                      ddl = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        selectedTime?.hour ?? 0,
                        selectedTime?.minute ?? 0,
                        0,
                      );
                    } else if (selectedTime != null) {
                      final now = DateTime.now();
                      ddl = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        selectedTime!.hour,
                        selectedTime!.minute,
                        0,
                      );
                    }

                    if (isEditing) {
                      final index = todos.indexOf(todo!);
                      if (index >= 0) {
                        todos[index] = Todo(
                          title: title,
                          done: todo!.done,
                          ddl: ddl,
                        );
                      }
                    } else {
                      todos.add(Todo(title: title, done: false, ddl: ddl));
                    }

                    setState(() {}); // 触发 UI 刷新
                    saveTodos(todos);
                    Navigator.pop(context);
                  },
                  child: Text(isEditing ? "保存" : "添加"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showTodoOptionsDialog(Todo todo, List<Todo> todos) async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("操作"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("删除待办"),
                onTap: () {
                  setState(() {
                    todos.remove(todo);
                  });
                  saveTodos(todos);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
          ],
        );
      },
    );
  }

  // ✅ 修改 _buildTodoGroup
  Widget _buildTodoGroup(
    String title,
    bool expanded,
    VoidCallback toggleExpanded,
    List<Todo> groupTodos,
    List<Todo> allTodos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGroupHeader(
          title: title,
          expanded: expanded,
          onTap: toggleExpanded,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: groupTodos.map((t) {
              // ✅ 用 Dismissible 包裹卡片
              return Dismissible(
                key: ValueKey(t.hashCode),
                // 每个 item 唯一 key
                direction: DismissDirection.endToStart,
                // 只允许左滑
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) async {
                  setState(() {
                    allTodos.remove(t);
                  });
                  await saveTodos(allTodos);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("已删除待办: ${t.title}")));
                },
                child: _buildTodoCard(t, allTodos), // 原来的卡片
              );
            }).toList(),
          ),
          crossFadeState: expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }

  // card 接收 master list（allTodos）
  Widget _buildTodoCard(Todo todo, List<Todo> todos) {
    final ddlText = _formatDdl(todo.ddl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Material(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTodoDialog(todos, todo: todo),
          onLongPress: () => _showTodoOptionsDialog(todo, todos), // ⬅️ 新增
          child: Container(
            constraints: const BoxConstraints(minHeight: 72),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Checkbox(
                  value: todo.done,
                  onChanged: (_) => _toggleDone(todo, todos),
                  fillColor: MaterialStateProperty.resolveWith<Color?>(
                    (states) => todo.done ? Colors.grey : null,
                  ),
                  checkColor: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0, end: todo.done ? 1 : 0),
                        duration: const Duration(milliseconds: 300),
                        builder: (context, value, child) {
                          return Stack(
                            children: [
                              Text(
                                todo.title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.normal,
                                  color: todo.done
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: value,
                                  child: Text(
                                    todo.title,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.normal,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (ddlText.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ddlText,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupHeader({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      trailing: Icon(expanded ? Icons.expand_less : Icons.expand_more),
      onTap: onTap,
    );
  }

  Widget _buildLoading() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 20),
        Text('正在拉取待办列表...'),
      ],
    ),
  );

  Widget _buildError(Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 50),
          const SizedBox(height: 20),
          const Text('获取待办列表失败', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _futureTodos = fetchTodos(); // 重试
              });
            },
            child: const Text('重试'),
          ),
        ],
      ),
    ),
  );

  int _selectedIndex = 0; // ⬅️ 在 State 里添加一个字段，记录当前页面索引

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Const.appName)),
      body: SafeArea(
        child: FutureBuilder<List<Todo>>(
          future: _futureTodos,
          builder: (context, snapshot) {
            if (_selectedIndex == 0) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoading();
              } else if (snapshot.hasError) {
                return _buildError(snapshot.error!);
              }

              final todos = snapshot.data ?? [];
              if (todos.isEmpty) return const Center(child: Text("暂无TODO"));

              final incompleteTodos = todos.where((t) => !t.done).toList();
              final completedTodos = todos.where((t) => t.done).toList();

              return ListView(
                children: [
                  _buildTodoGroup(
                    "未完成",
                    _incompleteExpanded,
                    () => setState(
                      () => _incompleteExpanded = !_incompleteExpanded,
                    ),
                    incompleteTodos,
                    todos,
                  ),
                  _buildTodoGroup(
                    "已完成",
                    _completedExpanded,
                    () => setState(
                      () => _completedExpanded = !_completedExpanded,
                    ),
                    completedTodos,
                    todos,
                  ),
                ],
              );
            } else {
              return AboutPage();
            }
          },
        ),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FutureBuilder<List<Todo>>(
              future: _futureTodos,
              builder: (context, snapshot) {
                final todos = snapshot.data ?? [];
                return FloatingActionButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      builder: (context) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text("手工录入"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showTodoDialog(todos); // 打开已有的添加对话框
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.upload_file),
                                title: const Text("从 Excel 导入"),
                                onTap: () {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("从 Excel 导入功能开发中..."),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child: const Icon(Icons.add),
                );
              },
            )
          : null,

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: "待办",
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outlined),
            selectedIcon: Icon(Icons.info_outlined),
            label: "关于",
          ),
        ],
      ),
    );
  }
}
