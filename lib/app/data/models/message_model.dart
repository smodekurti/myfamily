// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/reaction_model.dart';
import '../models/read_receipt_model.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    @JsonKey(name: 'family_id') required String familyId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'channel_id') @Default('general') String channelId,
    @JsonKey(name: 'channel_type') @Default('family') String channelType,
    @JsonKey(name: 'created_at') required DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'message_reactions')
    @Default([])
    List<ReactionModel> reactions,
    @JsonKey(name: 'message_reads') @Default([]) List<ReadReceiptModel> reads,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);
}
