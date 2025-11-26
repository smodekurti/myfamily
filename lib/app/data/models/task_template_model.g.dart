// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TaskTemplateModelImpl _$$TaskTemplateModelImplFromJson(
  Map<String, dynamic> json,
) => _$TaskTemplateModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  priority: json['priority'] as String?,
  points: (json['points'] as num?)?.toInt(),
  recurrenceType: json['recurrenceType'] as String?,
  recurrenceEndDate: json['recurrenceEndDate'] == null
      ? null
      : DateTime.parse(json['recurrenceEndDate'] as String),
  createdBy: json['createdBy'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$TaskTemplateModelImplToJson(
  _$TaskTemplateModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'name': instance.name,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'priority': instance.priority,
  'points': instance.points,
  'recurrenceType': instance.recurrenceType,
  'recurrenceEndDate': instance.recurrenceEndDate?.toIso8601String(),
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
