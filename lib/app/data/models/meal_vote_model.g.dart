// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_vote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealVoteSessionModelImpl _$$MealVoteSessionModelImplFromJson(
  Map<String, dynamic> json,
) => _$MealVoteSessionModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  mealDate: DateTime.parse(json['mealDate'] as String),
  mealType: json['mealType'] as String,
  options: (json['options'] as List<dynamic>)
      .map((e) => MealVoteOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  votes:
      (json['votes'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ) ??
      const {},
  status: json['status'] as String? ?? 'active',
  winnerOptionIndex: (json['winnerOptionIndex'] as num?)?.toInt(),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$MealVoteSessionModelImplToJson(
  _$MealVoteSessionModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'mealDate': instance.mealDate.toIso8601String(),
  'mealType': instance.mealType,
  'options': instance.options,
  'votes': instance.votes,
  'status': instance.status,
  'winnerOptionIndex': instance.winnerOptionIndex,
  'createdAt': instance.createdAt?.toIso8601String(),
};

_$MealVoteOptionImpl _$$MealVoteOptionImplFromJson(Map<String, dynamic> json) =>
    _$MealVoteOptionImpl(
      title: json['title'] as String,
      description: json['description'] as String,
    );

Map<String, dynamic> _$$MealVoteOptionImplToJson(
  _$MealVoteOptionImpl instance,
) => <String, dynamic>{
  'title': instance.title,
  'description': instance.description,
};
