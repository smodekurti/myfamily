import 'package:freezed_annotation/freezed_annotation.dart';

part 'task_template_model.freezed.dart';
part 'task_template_model.g.dart';

/// Task template - reusable task configurations
@freezed
class TaskTemplateModel with _$TaskTemplateModel {
  const factory TaskTemplateModel({
    required String id,
    required String familyId,
    required String name,
    required String title,
    String? description,
    String? category,
    String? priority,
    int? points,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _TaskTemplateModel;

  factory TaskTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$TaskTemplateModelFromJson(json);
}

// Helper functions for Supabase integration
class TaskTemplateModelHelpers {
  static TaskTemplateModel fromSupabase(Map<String, dynamic> json) => TaskTemplateModel(
    id: json['id'] as String,
    familyId: json['family_id'] as String,
    name: json['name'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    category: json['category'] as String?,
    priority: json['priority'] as String?,
    points: json['points'] as int?,
    recurrenceType: json['recurrence_type'] as String?,
    recurrenceEndDate: json['recurrence_end_date'] != null
        ? DateTime.parse(json['recurrence_end_date'] as String)
        : null,
    createdBy: json['created_by'] as String,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
  );

  static Map<String, dynamic> toSupabase(TaskTemplateModel template) => {
    'id': template.id,
    'family_id': template.familyId,
    'name': template.name,
    'title': template.title,
    'description': template.description,
    'category': template.category,
    'priority': template.priority,
    'points': template.points,
    'recurrence_type': template.recurrenceType,
    'recurrence_end_date': template.recurrenceEndDate?.toIso8601String(),
    'created_by': template.createdBy,
    'created_at': template.createdAt?.toIso8601String(),
    'updated_at': template.updatedAt?.toIso8601String(),
  };
}

