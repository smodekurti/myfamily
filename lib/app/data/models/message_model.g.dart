// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MessageModelImpl _$$MessageModelImplFromJson(Map<String, dynamic> json) =>
    _$MessageModelImpl(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String,
      mediaUrl: json['media_url'] as String?,
      channelId: json['channel_id'] as String? ?? 'general',
      channelType: json['channel_type'] as String? ?? 'family',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      reactions:
          (json['message_reactions'] as List<dynamic>?)
              ?.map((e) => ReactionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reads:
          (json['message_reads'] as List<dynamic>?)
              ?.map((e) => ReadReceiptModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$MessageModelImplToJson(_$MessageModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'family_id': instance.familyId,
      'sender_id': instance.senderId,
      'content': instance.content,
      'media_url': instance.mediaUrl,
      'channel_id': instance.channelId,
      'channel_type': instance.channelType,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'message_reactions': instance.reactions,
      'message_reads': instance.reads,
    };
