// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnnouncementModelImpl _$$AnnouncementModelImplFromJson(
  Map<String, dynamic> json,
) => _$AnnouncementModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  title: json['title'] as String,
  message: json['message'] as String,
  createdBy: json['createdBy'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  readBy:
      (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$$AnnouncementModelImplToJson(
  _$AnnouncementModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'title': instance.title,
  'message': instance.message,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'readBy': instance.readBy,
};
