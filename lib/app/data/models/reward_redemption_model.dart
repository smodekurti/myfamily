import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward_redemption_model.freezed.dart';
part 'reward_redemption_model.g.dart';

@freezed
class RewardRedemptionModel with _$RewardRedemptionModel {
  const factory RewardRedemptionModel({
    required String id,
    required String familyId,
    required String rewardId,
    required String userId,
    required int costAtRedemption,
    @Default('pending')
    String status, // 'pending', 'approved', 'fulfilled', 'rejected'
    DateTime? redeemedAt,
    DateTime? updatedAt,
    // Optional: Include joined Reward data for easy display
    String? rewardTitle,
    String? rewardIcon,
    String? userName, // Who redeemed it
  }) = _RewardRedemptionModel;

  factory RewardRedemptionModel.fromJson(Map<String, dynamic> json) =>
      _$RewardRedemptionModelFromJson(json);
}

class RewardRedemptionModelHelpers {
  static RewardRedemptionModel fromSupabase(Map<String, dynamic> json) {
    // Handle joined data if available
    String? rewardTitle;
    String? rewardIcon;
    String? userName;

    if (json['rewards'] != null) {
      final reward = json['rewards'];
      rewardTitle = reward['title'];
      rewardIcon = reward['icon'];
    }

    // Note: User profile join might be different depending on query

    return RewardRedemptionModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      rewardId: json['reward_id'] as String,
      userId: json['user_id'] as String,
      costAtRedemption: json['cost_at_redemption'] as int,
      status: json['status'] as String? ?? 'pending',
      redeemedAt: json['redeemed_at'] != null
          ? DateTime.parse(json['redeemed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      rewardTitle: rewardTitle,
      rewardIcon: rewardIcon,
      userName: userName,
    );
  }

  static Map<String, dynamic> toSupabase(RewardRedemptionModel redemption) => {
    'id': redemption.id,
    'family_id': redemption.familyId,
    'reward_id': redemption.rewardId,
    'user_id': redemption.userId,
    'cost_at_redemption': redemption.costAtRedemption,
    'status': redemption.status,
    'redeemed_at': redemption.redeemedAt?.toIso8601String(),
    'updated_at': redemption.updatedAt?.toIso8601String(),
  };
}

enum RedemptionStatus {
  pending('pending'),
  approved('approved'),
  fulfilled('fulfilled'),
  rejected('rejected');

  const RedemptionStatus(this.value);
  final String value;

  static RedemptionStatus fromString(String status) {
    return RedemptionStatus.values.firstWhere(
      (e) => e.value == status,
      orElse: () => RedemptionStatus.pending,
    );
  }
}
