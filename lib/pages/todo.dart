import 'dart:io';

import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/storage.dart';
import 'dart:async';
import 'package:todolist/pages/about.dart';
import 'package:file_picker/file_picker.dart';
import 'package:todolist/core/excel_importer.dart';
import 'package:todolist/utils/permission.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Todo>> _futureTodos;

  bool _incompleteExpanded = true;
  bool _completedExpanded = false;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureTodos = fetchTodos();
  }

  void _toggleDone(Todo todo, List<Todo> allTodos) {
    setState(() {
      final index = allTodos.indexOf(todo);
      if (index >= 0) {
        allTodos[index] = Todo(
          title: todo.title,
          done: !todo.done,
          weekday: todo.weekday,
          time: todo.time,
        );
      }
    });
    saveTodos(allTodos);
  }

  String _formatDdl(Todo todo) {
    if (todo.weekday == null && todo.time == null) return "";
    const weekdays = ["周一", "周二", "周三", "周四", "周五", "周六", "周日"];
    final dayStr = todo.weekday != null ? weekdays[todo.weekday! - 1] : "";
    final timeStr = todo.time != null
        ? "${todo.time!.hour.toString().padLeft(2, '0')}:${todo.time!.minute.toString().padLeft(2, '0')}"
        : "";
    if (dayStr.isNotEmpty && timeStr.isNotEmpty) return "$dayStr $timeStr";
    return dayStr.isNotEmpty ? dayStr : timeStr;
  }

  Future<void> _showTodoDialog(List<Todo> todos, {Todo? todo}) async {
    final isEditing = todo != null;
    final _titleController = TextEditingController(text: todo?.title ?? "");
    int? selectedWeekday = todo?.weekday; // 1-7
    TimeOfDay? selectedTime = todo?.time;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "编辑待办" : "添加待办"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleController,
                      maxLines: 3,
                      minLines: 1,
                      decoration: const InputDecoration(
                        labelText: "名称",
                        border: OutlineInputBorder(),
                        hintText: "可使用换行输入多行内容",
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
                              selectedWeekday != null
                                  ? "${["周一", "周二", "周三", "周四", "周五", "周六", "周日"][selectedWeekday! - 1]}"
                                  : "未选择",
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
                          child: DropdownButton<int>(
                            value: selectedWeekday,
                            hint: const Text("选择星期"),
                            isExpanded: true,
                            items: List.generate(7, (index) {
                              return DropdownMenuItem(
                                value: index + 1,
                                child: Text(
                                  [
                                    "周一",
                                    "周二",
                                    "周三",
                                    "周四",
                                    "周五",
                                    "周六",
                                    "周日",
                                  ][index],
                                ),
                              );
                            }),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedWeekday = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            child: Text(
                              selectedTime != null
                                  ? "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}"
                                  : "选择时间",
                            ),
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

                    if (isEditing) {
                      final index = todos.indexOf(todo!);
                      if (index >= 0) {
                        todos[index] = Todo(
                          title: title,
                          done: todo.done,
                          weekday: selectedWeekday,
                          time: selectedTime,
                        );
                      }
                    } else {
                      todos.add(
                        Todo(
                          title: title,
                          done: false,
                          weekday: selectedWeekday,
                          time: selectedTime,
                        ),
                      );
                    }

                    setState(() {}); // 刷新 UI
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

  /// Excel 导入功能
  Future<void> _importFromExcel(List<Todo> currentTodos) async {
    try {
      var granted = await checkStoragePermission();
      // if (!granted) {
      //   if (!mounted) return;
      //   ScaffoldMessenger.of(
      //     context,
      //   ).showSnackBar(const SnackBar(content: Text("请先授予存储权限")));
      //   return;
      // }

      // 选择文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xls', 'xlsx'],
      );

      if (result == null) {
        logger.w("用户取消了选择文件");
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        logger.e("无法获取文件路径: ${result.files.single}");
        return;
      }

      logger.e("成功获取文件路径$filePath");

      // 显示加载对话框
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在导入课程表...'),
                ],
              ),
            ),
          ),
        ),
      );

      final file = File(filePath);
      final bytes = await file.readAsBytes();

      final importedTodos = await CourseImporter.importFromBytes(bytes);

      // 合并到现有待办
      final mergedTodos = CourseImporter.mergeWithExisting(
        currentTodos,
        importedTodos,
      );

      // 保存
      await saveTodos(mergedTodos);

      // 刷新数据
      setState(() {
        _futureTodos = fetchTodos();
      });

      // 关闭加载对话框
      if (!mounted) return;
      Navigator.pop(context);

      // 显示成功消息
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('成功导入 ${importedTodos.length} 门课程'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e,stackTrace) {

      // 关闭加载对话框（如果存在）
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // 显示错误消息
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导入失败'),
          content: SingleChildScrollView(child: Text('错误详情：\n$e\n$stackTrace')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

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
              return Dismissible(
                key: ValueKey(t.hashCode),
                direction: DismissDirection.endToStart,
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
                child: _buildTodoCard(t, allTodos),
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

  // 默认选中今天的 weekday + 未指定
  Set<int?> _selectedWeekdays = {
    DateTime.now().weekday, // 1=周一 ... 7=周日
    null, // 表示未指定
  };

  Widget _buildTodoCard(Todo todo, List<Todo> todos) {
    final ddlText = _formatDdl(todo);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Material(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTodoDialog(todos, todo: todo),
          onLongPress: () => _showTodoOptionsDialog(todo, todos),
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
                const Icon(Icons.chevron_right, color: Colors.grey, size: 0),
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
          const Text('拉取待办列表失败', style: TextStyle(fontSize: 18)),
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
                _futureTodos = fetchTodos();
              });
            },
            child: const Text('重试'),
          ),
        ],
      ),
    ),
  );

  Future<void> _showWeekdayFilterDialog() async {
    final tempSelection = Set<int?>.from(_selectedWeekdays);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("选择要显示的星期"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(7, (index) {
                    int weekday = index + 1; // 1=周一
                    return CheckboxListTile(
                      title: Text(
                        "周${["一", "二", "三", "四", "五", "六", "日"][index]}",
                      ),
                      value: tempSelection.contains(weekday),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true)
                            tempSelection.add(weekday);
                          else
                            tempSelection.remove(weekday);
                        });
                      },
                    );
                  }),
                  CheckboxListTile(
                    title: const Text("未指定"),
                    value: tempSelection.contains(null),
                    onChanged: (checked) {
                      setDialogState(() {
                        if (checked == true)
                          tempSelection.add(null);
                        else
                          tempSelection.remove(null);
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedWeekdays = tempSelection;
                });
                Navigator.pop(context);
              },
              child: const Text("确定"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Const.appName),
        actions: _selectedIndex == 0
            ? [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: "按星期过滤",
                  onPressed: _showWeekdayFilterDialog,
                ),
              ]
            : null,
      ),
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
              final filteredTodos = todos.where((t) {
                if (t.weekday == null) return _selectedWeekdays.contains(null);
                return _selectedWeekdays.contains(t.weekday);
              }).toList();

              final incompleteTodos = filteredTodos
                  .where((t) => !t.done)
                  .toList();
              final completedTodos = filteredTodos
                  .where((t) => t.done)
                  .toList();

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
              return const AboutPage();
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
                                  _showTodoDialog(todos);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.upload_file),
                                title: const Text("从 Excel 导入课表"),
                                onTap: () {
                                  Navigator.pop(context);
                                  _importFromExcel(todos);
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
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
