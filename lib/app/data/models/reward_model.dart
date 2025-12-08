import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward_model.freezed.dart';
part 'reward_model.g.dart';

@freezed
class RewardModel with _$RewardModel {
  const factory RewardModel({
    required String id,
    required String familyId,
    required String createdBy,
    required String title,
    String? description,
    @Default(0) int cost,
    @Default('star') String icon,
    @Default(true) bool isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _RewardModel;

  factory RewardModel.fromJson(Map<String, dynamic> json) =>
      _$RewardModelFromJson(json);
}

class RewardModelHelpers {
  static RewardModel fromSupabase(Map<String, dynamic> json) => RewardModel(
    id: json['id'] as String,
    familyId: json['family_id'] as String,
    createdBy: json['created_by'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    cost: json['cost'] as int? ?? 0,
    icon: json['icon'] as String? ?? 'star',
    isActive: json['is_active'] as bool? ?? true,
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : null,
  );

  static Map<String, dynamic> toSupabase(RewardModel reward) => {
    'id': reward.id,
    'family_id': reward.familyId,
    'created_by': reward.createdBy,
    'title': reward.title,
    'description': reward.description,
    'cost': reward.cost,
    'icon': reward.icon,
    'is_active': reward.isActive,
    'created_at': reward.createdAt?.toIso8601String(),
    'updated_at': reward.updatedAt?.toIso8601String(),
  };
}
