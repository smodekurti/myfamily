// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealPlanModelImpl _$$MealPlanModelImplFromJson(Map<String, dynamic> json) =>
    _$MealPlanModelImpl(
      id: json['id'] as String,
      familyId: json['familyId'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      entries: (json['entries'] as List<dynamic>?)
          ?.map((e) => MealPlanEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MealPlanModelImplToJson(_$MealPlanModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'familyId': instance.familyId,
      'startDate': instance.startDate.toIso8601String(),
      'endDate': instance.endDate.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'entries': instance.entries,
    };

_$MealPlanEntryModelImpl _$$MealPlanEntryModelImplFromJson(
  Map<String, dynamic> json,
) => _$MealPlanEntryModelImpl(
  id: json['id'] as String,
  planId: json['planId'] as String,
  recipeId: json['recipeId'] as String?,
  mealDate: DateTime.parse(json['mealDate'] as String),
  mealType: json['mealType'] as String,
  customNote: json['customNote'] as String?,
  isCompleted: json['isCompleted'] as bool? ?? false,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  recipeTitle: json['recipeTitle'] as String?,
  recipeImageUrl: json['recipeImageUrl'] as String?,
);

Map<String, dynamic> _$$MealPlanEntryModelImplToJson(
  _$MealPlanEntryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'planId': instance.planId,
  'recipeId': instance.recipeId,
  'mealDate': instance.mealDate.toIso8601String(),
  'mealType': instance.mealType,
  'customNote': instance.customNote,
  'isCompleted': instance.isCompleted,
  'createdAt': instance.createdAt?.toIso8601String(),
  'recipeTitle': instance.recipeTitle,
  'recipeImageUrl': instance.recipeImageUrl,
};
