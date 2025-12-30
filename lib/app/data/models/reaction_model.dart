// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_model.freezed.dart';
part 'reaction_model.g.dart';

@freezed
class ReactionModel with _$ReactionModel {
  const factory ReactionModel({
    required String id,
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'user_id') required String userId,
    required String emoji,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReactionModel;

  factory ReactionModel.fromJson(Map<String, dynamic> json) =>
      _$ReactionModelFromJson(json);
}
