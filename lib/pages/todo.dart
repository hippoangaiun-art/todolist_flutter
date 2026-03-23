import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/todo_rules.dart';
import 'package:todolist/data/todo_repository.dart';
import 'package:todolist/models/todo_item_v2.dart';
import 'package:todolist/widgets/gradient_background.dart';

enum _TodoFilter {
  all,
  active,
  done,
}

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final TodoRepository _repository = TodoRepository();
  List<TodoItemV2> _todos = const [];
  bool _loading = true;
  DateTime _selectedDate = TodoRules.normalize(DateTime.now());
  _TodoFilter _filter = _TodoFilter.all;

  @override
  void initState() {
    super.initState();
    _loadTodos();
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
    });
  }

  Future<void> _toggleDone(TodoOccurrence occurrence) async {
    final idx = _todos.indexWhere((e) => e.id == occurrence.todo.id);
    if (idx < 0) {
      return;
    }
    setState(() {
      _todos[idx] = TodoRules.toggleDoneOnDate(_todos[idx], occurrence.date);
    });
    await _saveTodos();
  }

  Future<void> _showEditDialog({TodoItemV2? todo}) async {
    final titleController = TextEditingController(text: todo?.title ?? '');
    DateTime selectedDate = TodoRules.normalize(todo?.date ?? _selectedDate);
    final selectedRepeat = <int>{...todo?.repeatWeekdays ?? const <int>[]};

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
                      title: const Text('日期'),
                      subtitle: Text(_formatDate(selectedDate)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          locale: const Locale('zh', 'CN'),
                        );
                        if (picked == null) {
                          return;
                        }
                        setDialogState(() {
                          selectedDate = TodoRules.normalize(picked);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Text('每周重复'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                        final weekday = index + 1;
                        final selected = selectedRepeat.contains(weekday);
                        return FilterChip(
                          label: Text(_weekdayLabel(weekday)),
                          selected: selected,
                          onSelected: (value) {
                            setDialogState(() {
                              if (value) {
                                selectedRepeat.add(weekday);
                              } else {
                                selectedRepeat.remove(weekday);
                              }
                            });
                          },
                        );
                      }),
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
                            date: selectedDate,
                            repeatWeekdays: selectedRepeat.toList()..sort(),
                            completedDates: const [],
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
                            date: selectedDate,
                            repeatWeekdays: selectedRepeat.toList()..sort(),
                            updatedAt: now,
                          );
                        }
                      }
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
    setState(() {
      _todos.removeWhere((e) => e.id == todo.id);
    });
    await _saveTodos();
  }

  List<TodoOccurrence> _applyFilter(List<TodoOccurrence> list) {
    switch (_filter) {
      case _TodoFilter.all:
        return list;
      case _TodoFilter.active:
        return list.where((e) => !e.done).toList();
      case _TodoFilter.done:
        return list.where((e) => e.done).toList();
    }
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

  List<BoxShadow> _shadowForTheme(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.dark) {
      return const [];
    }
    return const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final allOccurrences = TodoRules.resolveForDate(_todos, _selectedDate);
    final occurrences = _applyFilter(allOccurrences);
    final doneCount = allOccurrences.where((e) => e.done).length;
    final activeCount = allOccurrences.length - doneCount;

    return Scaffold(
      appBar: AppBar(
        title: Text(Const.appName),
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: false,
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                                });
                              },
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: _pickDate,
                                child: Ink(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    color: _softSurface(context),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.today_outlined, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${_formatDate(_selectedDate)} ${_weekdayLabel(_selectedDate.weekday)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _selectedDate = _selectedDate.add(const Duration(days: 1));
                                });
                              },
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: _softSurfaceStrong(context),
                            boxShadow: _shadowForTheme(context),
                          ),
                          child: Row(
                            children: [
                              Expanded(child: _buildStat('总数', allOccurrences.length.toString())),
                              Expanded(child: _buildStat('进行中', activeCount.toString())),
                              Expanded(child: _buildStat('已完成', doneCount.toString())),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('全部'),
                              selected: _filter == _TodoFilter.all,
                              onSelected: (_) => setState(() => _filter = _TodoFilter.all),
                            ),
                            ChoiceChip(
                              label: const Text('未完成'),
                              selected: _filter == _TodoFilter.active,
                              onSelected: (_) => setState(() => _filter = _TodoFilter.active),
                            ),
                            ChoiceChip(
                              label: const Text('已完成'),
                              selected: _filter == _TodoFilter.done,
                              onSelected: (_) => setState(() => _filter = _TodoFilter.done),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: occurrences.isEmpty
                          ? const Center(
                              key: ValueKey('todo-empty'),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 42),
                                  SizedBox(height: 8),
                                  Text('这一天暂无待办'),
                                ],
                              ),
                            )
                          : ListView.separated(
                              key: const ValueKey('todo-list'),
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              itemCount: occurrences.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final occurrence = occurrences[index];
                                final todo = occurrence.todo;
                                return TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: Duration(milliseconds: 180 + index * 40),
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
                                    key: ValueKey('${todo.id}_${occurrence.date.toIso8601String()}'),
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
                                                value: occurrence.done,
                                                onChanged: (_) => _toggleDone(occurrence),
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
                                                        decoration: occurrence.done ? TextDecoration.lineThrough : null,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Wrap(
                                                      spacing: 6,
                                                      runSpacing: 6,
                                                      children: [
                                                        _buildTag(context, _formatDate(TodoRules.normalize(todo.date))),
                                                        if (todo.repeatWeekdays.isNotEmpty)
                                                          ...todo.repeatWeekdays.map((e) => _buildTag(context, _weekdayLabel(e))),
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
                                );
                              },
                            ),
                    ),
                  ),
                ],
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
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
