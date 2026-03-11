import 'package:flutter/material.dart';

enum TaskStatus { todo, inProgress, done }

class Task {
  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.status = TaskStatus.todo,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  TaskStatus status;
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<Task> _tasks = [];

  void _addTask() async {
    final task = await showDialog<Task>(
      context: context,
      builder: (context) => const _EditTaskDialog(),
    );

    if (task != null) {
      setState(() {
        _tasks.add(task);
      });
    }
  }

  void _editTask(Task task) async {
    final updated = await showDialog<Task>(
      context: context,
      builder: (context) => _EditTaskDialog(existing: task),
    );

    if (updated != null) {
      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updated;
        }
      });
    }
  }

  void _deleteTask(Task task) {
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return 'To do';
      case TaskStatus.inProgress:
        return 'In progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  Color _statusColor(BuildContext context, TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Theme.of(context).colorScheme.primary.withOpacity(0.1);
      case TaskStatus.inProgress:
        return Theme.of(context).colorScheme.tertiary.withOpacity(0.12);
      case TaskStatus.done:
        return Colors.green.withOpacity(0.12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks & Reminders'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
      body: _tasks.isEmpty
          ? const Center(
              child: Text(
                'No tasks yet.\nUse the + button to add your first task.',
                textAlign: TextAlign.center,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: ValueKey(task.id),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    color: Colors.redAccent,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteTask(task),
                  child: InkWell(
                    onTap: () => _editTask(task),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _statusColor(context, task.status),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.6),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _TaskSummary(
                              task: task,
                              statusLabel: _statusLabel(task.status),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            task.status == TaskStatus.done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TaskSummary extends StatelessWidget {
  const _TaskSummary({
    required this.task,
    required this.statusLabel,
  });

  final Task task;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final due = task.dueDate;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          task.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (task.description != null && task.description!.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              task.description!,
              style: textTheme.bodyMedium,
            ),
          ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            Chip(
              label: Text(statusLabel),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            if (due != null)
              Chip(
                label: Text('Due ${_formatDate(due)}'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}

class _EditTaskDialog extends StatefulWidget {
  const _EditTaskDialog({this.existing});

  final Task? existing;

  @override
  State<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends State<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _dueDate;
  late TaskStatus _status;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _descriptionController =
        TextEditingController(text: existing?.description ?? '');
    _dueDate = existing?.dueDate;
    _status = existing?.status ?? TaskStatus.todo;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now;
    final result = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (result != null) {
      setState(() {
        _dueDate = result;
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    final existing = widget.existing;
    final task = Task(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: _dueDate,
      status: _status,
    );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return AlertDialog(
      title: Text(isEditing ? 'Edit task' : 'New task'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'No due date'
                        : 'Due ${_formatDate(_dueDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: _pickDate,
                  child: const Text('Pick date'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TaskStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
              ),
              items: const [
                DropdownMenuItem(
                  value: TaskStatus.todo,
                  child: Text('To do'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.inProgress,
                  child: Text('In progress'),
                ),
                DropdownMenuItem(
                  value: TaskStatus.done,
                  child: Text('Done'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEditing ? 'Save' : 'Add'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)}';
  }

  String _two(int value) => value.toString().padLeft(2, '0');
}
