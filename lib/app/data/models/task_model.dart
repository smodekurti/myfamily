import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_model.freezed.dart';
part 'task_model.g.dart';

@freezed
class TaskModel with _$TaskModel {
  const factory TaskModel({
    required String id,
    required String familyId,
    required String title,
    String? description,
    required String assignedTo, // User ID - matches schema
    required String createdBy, // User ID who created the task
    @Default('pending') String status, // 'pending', 'in_progress', 'completed'
    @Default('medium') String priority, // 'low', 'medium', 'high'
    @Default('chore') String category, // 'chore', 'grocery', 'event', etc.
    Map<String, dynamic>? categoryData, // Category-specific data (e.g., groceryListId)
    DateTime? dueDate,
    @Default(10) int points,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) = _TaskModel;

  factory TaskModel.fromJson(Map<String, dynamic> json) => _$TaskModelFromJson(json);
}

// Helper functions for Supabase integration
class TaskModelHelpers {
  static TaskModel fromSupabase(Map<String, dynamic> json) => TaskModel(
    id: json['id'] as String,
    familyId: json['family_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    assignedTo: json['assigned_to'] as String,
    createdBy: json['created_by'] as String,
    status: json['status'] as String? ?? 'pending',
    priority: json['priority'] as String? ?? 'medium',
    category: json['category'] as String? ?? 'chore',
    categoryData: json['category_data'] != null
        ? Map<String, dynamic>.from(json['category_data'] as Map)
        : null,
    dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
    points: json['points'] as int? ?? 10,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
  );

  static Map<String, dynamic> toSupabase(TaskModel task) => {
    'id': task.id,
    'family_id': task.familyId,
    'title': task.title,
    'description': task.description,
    'assigned_to': task.assignedTo,
    'created_by': task.createdBy,
    'status': task.status,
    'priority': task.priority,
    'category': task.category,
    'category_data': task.categoryData,
    'due_date': task.dueDate?.toIso8601String(),
    'points': task.points,
    'created_at': task.createdAt?.toIso8601String(),
    'updated_at': task.updatedAt?.toIso8601String(),
    'completed_at': task.completedAt?.toIso8601String(),
  };
}

// Task status enum for better type safety
enum TaskStatus {
  pending('pending'),
  inProgress('in_progress'),
  completed('completed');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromString(String status) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => TaskStatus.pending,
    );
  }
}

// Task priority enum
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromString(String priority) {
    return TaskPriority.values.firstWhere(
      (e) => e.value == priority,
      orElse: () => TaskPriority.medium,
    );
  }
}