// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_redemption_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RewardRedemptionModelImpl _$$RewardRedemptionModelImplFromJson(
  Map<String, dynamic> json,
) => _$RewardRedemptionModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  rewardId: json['rewardId'] as String,
  userId: json['userId'] as String,
  costAtRedemption: (json['costAtRedemption'] as num).toInt(),
  status: json['status'] as String? ?? 'pending',
  redeemedAt: json['redeemedAt'] == null
      ? null
      : DateTime.parse(json['redeemedAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  rewardTitle: json['rewardTitle'] as String?,
  rewardIcon: json['rewardIcon'] as String?,
  userName: json['userName'] as String?,
);

Map<String, dynamic> _$$RewardRedemptionModelImplToJson(
  _$RewardRedemptionModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'rewardId': instance.rewardId,
  'userId': instance.userId,
  'costAtRedemption': instance.costAtRedemption,
  'status': instance.status,
  'redeemedAt': instance.redeemedAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'rewardTitle': instance.rewardTitle,
  'rewardIcon': instance.rewardIcon,
  'userName': instance.userName,
};
