// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AchievementModelImpl _$$AchievementModelImplFromJson(
  Map<String, dynamic> json,
) => _$AchievementModelImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  familyId: json['familyId'] as String,
  achievementId: json['achievementId'] as String,
  unlockedAt: DateTime.parse(json['unlockedAt'] as String),
);

Map<String, dynamic> _$$AchievementModelImplToJson(
  _$AchievementModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'familyId': instance.familyId,
  'achievementId': instance.achievementId,
  'unlockedAt': instance.unlockedAt.toIso8601String(),
};
