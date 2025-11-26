// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'points_history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PointsHistoryModelImpl _$$PointsHistoryModelImplFromJson(
  Map<String, dynamic> json,
) => _$PointsHistoryModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  userId: json['userId'] as String,
  points: (json['points'] as num).toInt(),
  reason: json['reason'] as String,
  taskId: json['taskId'] as String?,
  taskTitle: json['taskTitle'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$PointsHistoryModelImplToJson(
  _$PointsHistoryModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'userId': instance.userId,
  'points': instance.points,
  'reason': instance.reason,
  'taskId': instance.taskId,
  'taskTitle': instance.taskTitle,
  'createdAt': instance.createdAt?.toIso8601String(),
};
