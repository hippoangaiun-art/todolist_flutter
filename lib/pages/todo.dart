import 'package:flutter/material.dart';
import 'package:todolist/core/todo_rules.dart';
import 'package:todolist/data/todo_repository.dart';
import 'package:todolist/models/todo_item_v2.dart';
import 'package:todolist/widgets/gradient_background.dart';
import 'package:todolist/widgets/surface_style.dart';

enum _TodoViewMode { all, byDate }

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoRepository _repository = TodoRepository();
  final TextEditingController _searchController = TextEditingController();
  List<TodoItemV2> _todos = const [];
  bool _loading = true;
  bool _completedExpanded = false;
  DateTime _selectedDate = TodoRules.normalize(DateTime.now());
  _TodoViewMode _viewMode = _TodoViewMode.all;
  String _searchKeyword = '';

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTodos() async {
    final todos = await _repository.fetchAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _todos = todos;
      _loading = false;
    });
  }

  Future<void> _saveTodos() async {
    await _repository.saveAll(_todos);
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int weekday) {
    const labels = ['一', '二', '三', '四', '五', '六', '日'];
    return '周${labels[weekday - 1]}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDate = TodoRules.normalize(picked);
      _completedExpanded = false;
    });
  }

  Future<void> _openFilterSheet() async {
    var localMode = _viewMode;
    var localDate = _selectedDate;

    final result = await showModalBottomSheet<_TodoFilterSelection>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '筛选方式',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  RadioGroup<_TodoViewMode>(
                    groupValue: localMode,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setModalState(() {
                        localMode = value;
                      });
                    },
                    child: Column(
                      children: [
                        const RadioListTile<_TodoViewMode>(
                          title: Text('全部任务'),
                          subtitle: Text('显示所有待办，不按日期限制'),
                          value: _TodoViewMode.all,
                        ),
                        RadioListTile<_TodoViewMode>(
                          title: const Text('按日期查看'),
                          subtitle: Text(
                            '当前日期：${_formatDate(localDate)} ${_weekdayLabel(localDate.weekday)}',
                          ),
                          value: _TodoViewMode.byDate,
                        ),
                      ],
                    ),
                  ),
                  if (localMode == _TodoViewMode.byDate)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 12, right: 4),
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('选择筛选日期'),
                      subtitle: Text(_formatDate(localDate)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: localDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          locale: const Locale('zh', 'CN'),
                        );
                        if (picked == null) {
                          return;
                        }
                        setModalState(() {
                          localDate = TodoRules.normalize(picked);
                        });
                      },
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('取消'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(sheetContext).pop(
                              _TodoFilterSelection(
                                mode: localMode,
                                date: localDate,
                              ),
                            );
                          },
                          child: const Text('应用'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }
    setState(() {
      _viewMode = result.mode;
      _selectedDate = result.date;
      _completedExpanded = false;
    });
  }

  Future<DateTime?> _pickEndAt(DateTime initial) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
    );
    if (pickedDate == null || !mounted) {
      return null;
    }
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (pickedTime == null) {
      return null;
    }
    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _toggleDone(TodoItemV2 todo) async {
    final idx = _todos.indexWhere((e) => e.id == todo.id);
    if (idx < 0) {
      return;
    }
    setState(() {
      _todos[idx] = TodoRules.toggleDone(_todos[idx]);
      _completedExpanded = false;
    });
    await _saveTodos();
  }

  Future<void> _showEditDialog({TodoItemV2? todo}) async {
    final titleController = TextEditingController(text: todo?.title ?? '');
    DateTime selectedEndAt = todo?.endAt ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(todo == null ? '新增待办' : '编辑待办'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: '标题',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('结束时间'),
                      subtitle: Text(
                        '${_formatDate(selectedEndAt)} ${_formatTime(selectedEndAt)}',
                      ),
                      trailing: const Icon(Icons.schedule),
                      onTap: () async {
                        final picked = await _pickEndAt(selectedEndAt);
                        if (picked == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedEndAt = picked;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () async {
                    final title = titleController.text.trim();
                    if (title.isEmpty) {
                      return;
                    }
                    final now = DateTime.now();
                    setState(() {
                      if (todo == null) {
                        _todos = [
                          TodoItemV2(
                            id: now.microsecondsSinceEpoch.toString(),
                            title: title,
                            done: false,
                            endAt: selectedEndAt,
                            createdAt: now,
                            updatedAt: now,
                          ),
                          ..._todos,
                        ];
                      } else {
                        final idx = _todos.indexWhere((e) => e.id == todo.id);
                        if (idx >= 0) {
                          _todos[idx] = _todos[idx].copyWith(
                            title: title,
                            endAt: selectedEndAt,
                            updatedAt: now,
                          );
                        }
                      }
                      _completedExpanded = false;
                    });
                    await _saveTodos();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(todo == null ? '创建' : '保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteTodo(TodoItemV2 todo) async {
    final removedIndex = _todos.indexWhere((e) => e.id == todo.id);
    if (removedIndex < 0) {
      return;
    }
    final removed = _todos[removedIndex];
    setState(() {
      _todos.removeAt(removedIndex);
      _completedExpanded = false;
    });
    await _saveTodos();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('已删除待办'),
        action: SnackBarAction(
          label: '撤销',
          onPressed: () async {
            if (!mounted) {
              return;
            }
            setState(() {
              _todos.insert(removedIndex, removed);
            });
            await _saveTodos();
          },
        ),
      ),
    );
  }

  List<TodoItemV2> _applySearch(List<TodoItemV2> list) {
    final keyword = _searchKeyword.trim().toLowerCase();
    if (keyword.isEmpty) {
      return list;
    }
    return list
        .where((todo) => todo.title.toLowerCase().contains(keyword))
        .toList();
  }

  Color _softSurface(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainerHigh;
    }
    return Colors.white.withValues(alpha: 0.82);
  }

  Color _softSurfaceStrong(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return scheme.surfaceContainer;
    }
    return Colors.white.withValues(alpha: 0.9);
  }

  Widget _buildTodoTile(TodoItemV2 todo, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 180 + index * 30),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Dismissible(
          key: ValueKey(todo.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) {
            _deleteTodo(todo);
          },
          background: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: SurfaceStyle.cardBorder(context),
              boxShadow: SurfaceStyle.cardShadow(context),
            ),
            child: Material(
              color: _softSurfaceStrong(context),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _showEditDialog(todo: todo),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Checkbox(
                        value: todo.done,
                        onChanged: (_) => _toggleDone(todo),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              todo.title,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                decoration:
                                    todo.done ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildTag(context, _formatDate(todo.endAt)),
                                _buildTag(context, _formatTime(todo.endAt)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.7 : 0.85,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                  _completedExpanded = false;
                });
              },
              decoration: const InputDecoration(
                hintText: '搜索待办标题',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          if (_searchKeyword.isNotEmpty)
            IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchKeyword = '';
                  _completedExpanded = false;
                });
              },
              icon: const Icon(Icons.cancel_outlined),
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildFoldHeader({
    required String title,
    required int count,
    required bool expanded,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: SurfaceStyle.cardBorder(context),
        boxShadow: SurfaceStyle.cardShadow(context),
      ),
      child: Material(
        color: _softSurfaceStrong(context),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(child: Text('$title ($count)')),
                Icon(
                  expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: SurfaceStyle.cardBorder(context),
        boxShadow: SurfaceStyle.cardShadow(context),
      ),
      child: Material(
        color: _softSurfaceStrong(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(child: Text('$title ($count)')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodoList(List<TodoItemV2> todos) {
    if (todos.isEmpty) {
      return const Center(
        key: ValueKey('todo-empty'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 42),
            SizedBox(height: 8),
            Text('暂无待办'),
          ],
        ),
      );
    }

    final activeTodos = todos.where((e) => !e.done).toList();
    final doneTodos = todos.where((e) => e.done).toList();

    return ListView(
      key: const ValueKey('todo-list-grouped'),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        if (activeTodos.isNotEmpty) ...[
          _buildSectionHeader(
            title: '未完成事项',
            count: activeTodos.length,
            icon: Icons.radio_button_unchecked,
          ),
          const SizedBox(height: 10),
          ...activeTodos.asMap().entries.map(
                (entry) => _buildTodoTile(entry.value, entry.key),
              ),
          const SizedBox(height: 8),
        ],
        if (doneTodos.isNotEmpty) ...[
          _buildFoldHeader(
            title: '已完成事项',
            count: doneTodos.length,
            expanded: _completedExpanded,
            onTap: () {
              setState(() {
                _completedExpanded = !_completedExpanded;
              });
            },
            icon: Icons.check_circle_outline,
          ),
          if (_completedExpanded) ...[
            const SizedBox(height: 10),
            ...doneTodos.asMap().entries.map(
                  (entry) => _buildTodoTile(
                    entry.value,
                    activeTodos.length + entry.key,
                  ),
                ),
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final allTodos = _viewMode == _TodoViewMode.all
        ? TodoRules.sortByEndAt(_todos)
        : TodoRules.resolveForDate(_todos, _selectedDate);
    final filteredTodos = _applySearch(allTodos);
    final doneCount = filteredTodos.where((e) => e.done).length;
    final activeCount = filteredTodos.length - doneCount;
    final topInset = MediaQuery.paddingOf(context).top + 68;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 12,
        toolbarHeight: 68,
        title: _buildSearchBar(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            onPressed: _openFilterSheet,
            tooltip: '筛选',
            icon: Icon(
              _viewMode == _TodoViewMode.all
                  ? Icons.filter_list_rounded
                  : Icons.filter_alt_rounded,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                      child: Column(
                        children: [
                          if (_viewMode == _TodoViewMode.byDate)
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = _selectedDate.subtract(
                                        const Duration(days: 1),
                                      );
                                      _completedExpanded = false;
                                    });
                                  },
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Expanded(
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: _pickDate,
                                    child: Ink(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: _softSurface(context),
                                        border: SurfaceStyle.cardBorder(context),
                                        boxShadow: SurfaceStyle.cardShadow(
                                          context,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.today_outlined,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${_formatDate(_selectedDate)} ${_weekdayLabel(_selectedDate.weekday)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedDate = _selectedDate.add(
                                        const Duration(days: 1),
                                      );
                                      _completedExpanded = false;
                                    });
                                  },
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          if (_viewMode == _TodoViewMode.byDate)
                            const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: _softSurfaceStrong(context),
                              border: SurfaceStyle.cardBorder(context),
                              boxShadow: SurfaceStyle.cardShadow(context),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildStat(
                                    '总数',
                                    filteredTodos.length.toString(),
                                  ),
                                ),
                                Expanded(
                                  child: _buildStat(
                                    '进行中',
                                    activeCount.toString(),
                                  ),
                                ),
                                Expanded(
                                  child: _buildStat('已完成', doneCount.toString()),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _buildTodoList(filteredTodos),
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditDialog(),
        icon: const Icon(Icons.add),
        label: const Text('新增待办'),
      ),
    );
  }

  Widget _buildTag(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Theme.of(context).colorScheme.secondaryContainer,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TodoFilterSelection {
  final _TodoViewMode mode;
  final DateTime date;

  const _TodoFilterSelection({required this.mode, required this.date});
}
