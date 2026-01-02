// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FamilyModelImpl _$$FamilyModelImplFromJson(Map<String, dynamic> json) =>
    _$FamilyModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      createdBy: json['created_by'] as String,
      members:
          (json['members'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      inviteCode: json['invite_code'] as String?,
      childInviteCode: json['child_invite_code'] as String?,
      inviteLink: json['invite_link'] as String?,
      address: json['address'] as String?,
      geminiApiKey: json['gemini_api_key'] as String?,
      themePreference: json['theme_preference'] as String? ?? 'system',
      totalPoints: (json['total_points'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
    );

Map<String, dynamic> _$$FamilyModelImplToJson(_$FamilyModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_by': instance.createdBy,
      'members': instance.members,
      'invite_code': instance.inviteCode,
      'child_invite_code': instance.childInviteCode,
      'invite_link': instance.inviteLink,
      'address': instance.address,
      'gemini_api_key': instance.geminiApiKey,
      'theme_preference': instance.themePreference,
      'total_points': instance.totalPoints,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'deleted_at': instance.deletedAt?.toIso8601String(),
    };

_$FamilyMemberModelImpl _$$FamilyMemberModelImplFromJson(
  Map<String, dynamic> json,
) => _$FamilyMemberModelImpl(
  uid: json['uid'] as String,
  displayName: json['displayName'] as String,
  photoURL: json['photoURL'] as String?,
  role: json['role'] as String,
  points: (json['points'] as num?)?.toInt() ?? 0,
  notificationTokens:
      (json['notificationTokens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  joinedAt: json['joinedAt'] == null
      ? null
      : DateTime.parse(json['joinedAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$FamilyMemberModelImplToJson(
  _$FamilyMemberModelImpl instance,
) => <String, dynamic>{
  'uid': instance.uid,
  'displayName': instance.displayName,
  'photoURL': instance.photoURL,
  'role': instance.role,
  'points': instance.points,
  'notificationTokens': instance.notificationTokens,
  'joinedAt': instance.joinedAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
