// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'read_receipt_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReadReceiptModelImpl _$$ReadReceiptModelImplFromJson(
  Map<String, dynamic> json,
) => _$ReadReceiptModelImpl(
  id: json['id'] as String,
  messageId: json['message_id'] as String,
  userId: json['user_id'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$$ReadReceiptModelImplToJson(
  _$ReadReceiptModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'message_id': instance.messageId,
  'user_id': instance.userId,
  'created_at': instance.createdAt.toIso8601String(),
};
