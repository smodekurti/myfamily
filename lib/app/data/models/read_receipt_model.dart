// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'read_receipt_model.freezed.dart';
part 'read_receipt_model.g.dart';

@freezed
class ReadReceiptModel with _$ReadReceiptModel {
  const factory ReadReceiptModel({
    required String id,
    @JsonKey(name: 'message_id') required String messageId,
    @JsonKey(name: 'user_id') required String userId,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ReadReceiptModel;

  factory ReadReceiptModel.fromJson(Map<String, dynamic> json) =>
      _$ReadReceiptModelFromJson(json);
}
