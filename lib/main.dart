import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = TaskRepository();
  await repository.init();
  runApp(TodoApp(repository: repository));
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomePage(repository: repository),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.repository});

  final TaskRepository repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Task> _tasks = [];
  bool _isLoading = true;
  TaskFilter _filter = TaskFilter.active;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    final savedTasks = await widget.repository.loadTasks();
    setState(() {
      _tasks
        ..clear()
        ..addAll(savedTasks);
      _isLoading = false;
    });
  }

  Future<void> _persist() async {
    await widget.repository.saveTasks(_tasks);
  }

  Future<void> _openEditor({Task? task}) async {
    final result = await Navigator.of(context).push<TaskEditorResult>(
      MaterialPageRoute(
        builder: (_) => TaskEditorPage(task: task),
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.shouldDelete && task != null) {
        _tasks.removeWhere((item) => item.id == task.id);
      } else if (result.task != null) {
        final idx = _tasks.indexWhere((item) => item.id == result.task!.id);
        if (idx == -1) {
          _tasks.add(result.task!);
        } else {
          _tasks[idx] = result.task!;
        }
      }
    });
    await _persist();
  }

  Future<void> _toggleTask(Task task, bool isDone) async {
    final idx = _tasks.indexWhere((item) => item.id == task.id);
    if (idx == -1) return;
    setState(() {
      _tasks[idx] = task.copyWith(isDone: isDone);
    });
    await _persist();
  }

  List<Task> get _visibleTasks {
    switch (_filter) {
      case TaskFilter.active:
        return _tasks.where((task) => !task.isDone).toList();
      case TaskFilter.completed:
        return _tasks.where((task) => task.isDone).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<TaskFilter>(
              segments: const [
                ButtonSegment(
                  value: TaskFilter.active,
                  icon: Icon(Icons.playlist_add_check_outlined),
                  label: Text('Текущие'),
                ),
                ButtonSegment(
                  value: TaskFilter.completed,
                  icon: Icon(Icons.done_all),
                  label: Text('Выполненные'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _visibleTasks.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: _visibleTasks.length,
                  separatorBuilder: (_, __) => const Divider(height: 0),
                  itemBuilder: (context, index) {
                    final task = _visibleTasks[index];
                    return ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration:
                              task.isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: task.description.isEmpty
                          ? null
                          : Text(
                              task.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (value) =>
                            _toggleTask(task, value ?? task.isDone),
                      ),
                      onTap: () => _openEditor(task: task),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Новая задача'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_available, size: 72, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'Нет запланированных задач',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Добавьте первую запись, чтобы начать планировать день.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TaskEditorPage extends StatefulWidget {
  const TaskEditorPage({super.key, this.task});

  final Task? task;

  @override
  State<TaskEditorPage> createState() => _TaskEditorPageState();
}

class _TaskEditorPageState extends State<TaskEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.task?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.task;
    final updated = (existing ?? Task.create())
        .copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
        )
        .normalize();
    Navigator.of(context).pop(
      TaskEditorResult(task: updated),
    );
  }

  void _handleDelete() {
    Navigator.of(context).pop(
      TaskEditorResult(shouldDelete: true, task: widget.task),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Редактирование' : 'Новая задача'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _handleDelete,
              tooltip: 'Удалить',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  hintText: 'Например, купить продукты',
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  hintText: 'Дополнительные детали',
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _handleSave,
                  child: Text(isEditing ? 'Сохранить' : 'Добавить'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TaskEditorResult {
  TaskEditorResult({this.task, this.shouldDelete = false});

  final Task? task;
  final bool shouldDelete;
}

enum TaskFilter { active, completed }

class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isDone,
    required this.createdAt,
  });

  factory Task.create() => Task(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: '',
        description: '',
        isDone: false,
        createdAt: DateTime.now(),
      );

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      isDone: map['isDone'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime createdAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isDone,
    DateTime? createdAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Task normalize() {
    return copyWith(
      title: title.trim(),
      description: description.trim(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class TaskRepository {
  final _storageKey = 'todo_tasks';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<List<Task>> loadTasks() async {
    final prefs = _ensurePrefs();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((item) => Task.fromMap(item as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final prefs = _ensurePrefs();
    final serialized = jsonEncode(tasks.map((task) => task.toMap()).toList());
    await prefs.setString(_storageKey, serialized);
  }

  SharedPreferences _ensurePrefs() {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError('Хранилище ещё не инициализировано');
    }
    return prefs;
  }
}
