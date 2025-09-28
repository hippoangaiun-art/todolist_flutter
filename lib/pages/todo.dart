import 'package:flutter/material.dart';
import 'package:todolist/core/const.dart';
import 'package:todolist/core/storage.dart';


class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late Future<List<Todo>> _futureTodos;

  @override
  void initState() {
    super.initState();
    _futureTodos = fetchTodos(); // 异步加载
  }

  void _toggleDone(Todo todo, List<Todo> todos) {
    setState(() {
      final index = todos.indexOf(todo);
      todos[index] = Todo(
        title: todo.title,
        done: !todo.done,
        ddl: todo.ddl,
      );
    });

    saveTodos(todos);
  }

  String _formatDdl(DateTime? ddl) {
    if (ddl == null) return "";
    return "截止:${ddl.year}-${ddl.month}-${ddl.day}";
  }

  Widget _buildTodoCard(Todo todo, List<Todo> todos) {
    final ddlText = _formatDdl(todo.ddl);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6),
      child: Material(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _toggleDone(todo, todos),
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
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题文字 + 左到右删除线动画覆盖文字
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
                                  color:
                                  todo.done ? Colors.grey : Colors.black87,
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

                      // ddl 条件显示
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

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('正在加载待办列表...'),
        ],
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
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
            )
          ],
        ),
      ),
    );
  }

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

            if (todos.isEmpty) {
              return const Center(child: Text("暂无TODO"));
            }

            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return _buildTodoCard(todo, todos);
              },
            );
          },
        ),
      ),
    );
  }
}
