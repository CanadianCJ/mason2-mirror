import 'package:uuid/uuid.dart';

enum TaskStatus {
  open,
  completed,
}

class Task {
  final String id;
  final String title;
  final String? notes;
  final DateTime? dueDate;
  final String? clientId;   // link to a contact if we want later
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueDate,
    this.clientId,
    this.status = TaskStatus.open,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? id,
    String? title,
    String? notes,
    DateTime? dueDate,
    String? clientId,
    TaskStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueDate: dueDate ?? this.dueDate,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Task.create(String title,
      {String? notes, DateTime? dueDate, String? clientId}) {
    final uuid = const Uuid();
    return Task(
      id: uuid.v4(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      clientId: clientId,
      status: TaskStatus.open,
    );
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      dueDate:
          json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      clientId: json['clientId'] as String?,
      status: (json['status'] as String) == 'completed'
          ? TaskStatus.completed
          : TaskStatus.open,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'dueDate': dueDate?.toIso8601String(),
      'clientId': clientId,
      'status': status == TaskStatus.completed ? 'completed' : 'open',
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
