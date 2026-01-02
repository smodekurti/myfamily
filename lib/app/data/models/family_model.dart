// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'family_model.freezed.dart';
part 'family_model.g.dart';

@freezed
class FamilyModel with _$FamilyModel {
  const factory FamilyModel({
    required String id,
    required String name,
    @JsonKey(name: 'created_by') required String createdBy,
    @Default([]) List<String> members,
    @JsonKey(name: 'invite_code') String? inviteCode,
    @JsonKey(name: 'child_invite_code') String? childInviteCode,
    @JsonKey(name: 'invite_link') String? inviteLink,
    String? address,
    @JsonKey(name: 'gemini_api_key') String? geminiApiKey,
    @JsonKey(name: 'theme_preference')
    @Default('system')
    String themePreference,
    @JsonKey(name: 'total_points') @Default(0) int totalPoints,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
  }) = _FamilyModel;

  factory FamilyModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyModelFromJson(json);
}

@freezed
class FamilyMemberModel with _$FamilyMemberModel {
  const factory FamilyMemberModel({
    required String uid,
    required String displayName,
    String? photoURL,
    required String role,
    @Default(0) int points,
    @Default([]) List<String> notificationTokens,
    DateTime? joinedAt,
    DateTime? updatedAt,
  }) = _FamilyMemberModel;

  factory FamilyMemberModel.fromJson(Map<String, dynamic> json) =>
      _$FamilyMemberModelFromJson(json);
}
