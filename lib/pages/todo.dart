import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/storage.dart'; // fetchTodos / saveTodos
import 'dart:async';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late Future<List<Todo>> _futureTodos;

  // 分组展开状态
  bool _incompleteExpanded = true;
  bool _completedExpanded = false;

  @override
  void initState() {
    super.initState();
    _futureTodos = fetchTodos();
  }

  void _toggleDone(Todo todo, List<Todo> todos) {
    setState(() {
      final index = todos.indexOf(todo);
      todos[index] = Todo(title: todo.title, done: !todo.done, ddl: todo.ddl);
    });

    saveTodos(todos); // 点击后立即保存
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
                      todos[index] = Todo(
                        title: title,
                        done: todo.done,
                        ddl: ddl,
                      );
                    } else {
                      todos.add(Todo(title: title, done: false, ddl: ddl));
                    }

                    setState(() {});
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

  Widget _buildTodoGroup(
    String title,
    bool expanded,
    VoidCallback toggleExpanded,
    List<Todo> todos,
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
          firstChild: Container(), // 收起状态
          secondChild: Column(children: todos.map((t) => _buildTodoCard(t, todos)).toList()), // 展开状态
          crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        )
      ],
    );
  }

  Widget _buildTodoCard(Todo todo, List<Todo> todos) {
    final ddlText = _formatDdl(todo.ddl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Material(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTodoDialog(todos, todo: todo),
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
                                    style: TextStyle(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(Const.appName)),
      body: SafeArea(
        child: FutureBuilder<List<Todo>>(
          future: _futureTodos,
          builder: (context, snapshot) {
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
                ),
                _buildTodoGroup(
                  "已完成",
                  _completedExpanded,
                  () =>
                      setState(() => _completedExpanded = !_completedExpanded),
                  completedTodos,
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FutureBuilder<List<Todo>>(
        future: _futureTodos,
        builder: (context, snapshot) {
          final todos = snapshot.data ?? [];
          return FloatingActionButton(
            onPressed: () => _showTodoDialog(todos),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
