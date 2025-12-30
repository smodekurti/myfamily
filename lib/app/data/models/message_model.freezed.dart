// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'message_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) {
  return _MessageModel.fromJson(json);
}

/// @nodoc
mixin _$MessageModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'family_id')
  String get familyId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sender_id')
  String get senderId => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'media_url')
  String? get mediaUrl => throw _privateConstructorUsedError;
  @JsonKey(name: 'channel_id')
  String get channelId => throw _privateConstructorUsedError;
  @JsonKey(name: 'channel_type')
  String get channelType => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_reactions')
  List<ReactionModel> get reactions => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_reads')
  List<ReadReceiptModel> get reads => throw _privateConstructorUsedError;

  /// Serializes this MessageModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MessageModelCopyWith<MessageModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MessageModelCopyWith<$Res> {
  factory $MessageModelCopyWith(
    MessageModel value,
    $Res Function(MessageModel) then,
  ) = _$MessageModelCopyWithImpl<$Res, MessageModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'family_id') String familyId,
    @JsonKey(name: 'sender_id') String senderId,
    String content,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'channel_id') String channelId,
    @JsonKey(name: 'channel_type') String channelType,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'message_reactions') List<ReactionModel> reactions,
    @JsonKey(name: 'message_reads') List<ReadReceiptModel> reads,
  });
}

/// @nodoc
class _$MessageModelCopyWithImpl<$Res, $Val extends MessageModel>
    implements $MessageModelCopyWith<$Res> {
  _$MessageModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? senderId = null,
    Object? content = null,
    Object? mediaUrl = freezed,
    Object? channelId = null,
    Object? channelType = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? reactions = null,
    Object? reads = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            familyId: null == familyId
                ? _value.familyId
                : familyId // ignore: cast_nullable_to_non_nullable
                      as String,
            senderId: null == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            mediaUrl: freezed == mediaUrl
                ? _value.mediaUrl
                : mediaUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            channelId: null == channelId
                ? _value.channelId
                : channelId // ignore: cast_nullable_to_non_nullable
                      as String,
            channelType: null == channelType
                ? _value.channelType
                : channelType // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reactions: null == reactions
                ? _value.reactions
                : reactions // ignore: cast_nullable_to_non_nullable
                      as List<ReactionModel>,
            reads: null == reads
                ? _value.reads
                : reads // ignore: cast_nullable_to_non_nullable
                      as List<ReadReceiptModel>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MessageModelImplCopyWith<$Res>
    implements $MessageModelCopyWith<$Res> {
  factory _$$MessageModelImplCopyWith(
    _$MessageModelImpl value,
    $Res Function(_$MessageModelImpl) then,
  ) = __$$MessageModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'family_id') String familyId,
    @JsonKey(name: 'sender_id') String senderId,
    String content,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'channel_id') String channelId,
    @JsonKey(name: 'channel_type') String channelType,
    @JsonKey(name: 'created_at') DateTime createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'message_reactions') List<ReactionModel> reactions,
    @JsonKey(name: 'message_reads') List<ReadReceiptModel> reads,
  });
}

/// @nodoc
class __$$MessageModelImplCopyWithImpl<$Res>
    extends _$MessageModelCopyWithImpl<$Res, _$MessageModelImpl>
    implements _$$MessageModelImplCopyWith<$Res> {
  __$$MessageModelImplCopyWithImpl(
    _$MessageModelImpl _value,
    $Res Function(_$MessageModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? senderId = null,
    Object? content = null,
    Object? mediaUrl = freezed,
    Object? channelId = null,
    Object? channelType = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? reactions = null,
    Object? reads = null,
  }) {
    return _then(
      _$MessageModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        senderId: null == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaUrl: freezed == mediaUrl
            ? _value.mediaUrl
            : mediaUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        channelId: null == channelId
            ? _value.channelId
            : channelId // ignore: cast_nullable_to_non_nullable
                  as String,
        channelType: null == channelType
            ? _value.channelType
            : channelType // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reactions: null == reactions
            ? _value._reactions
            : reactions // ignore: cast_nullable_to_non_nullable
                  as List<ReactionModel>,
        reads: null == reads
            ? _value._reads
            : reads // ignore: cast_nullable_to_non_nullable
                  as List<ReadReceiptModel>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MessageModelImpl implements _MessageModel {
  const _$MessageModelImpl({
    required this.id,
    @JsonKey(name: 'family_id') required this.familyId,
    @JsonKey(name: 'sender_id') required this.senderId,
    required this.content,
    @JsonKey(name: 'media_url') this.mediaUrl,
    @JsonKey(name: 'channel_id') this.channelId = 'general',
    @JsonKey(name: 'channel_type') this.channelType = 'family',
    @JsonKey(name: 'created_at') required this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'message_reactions')
    final List<ReactionModel> reactions = const [],
    @JsonKey(name: 'message_reads')
    final List<ReadReceiptModel> reads = const [],
  }) : _reactions = reactions,
       _reads = reads;

  factory _$MessageModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MessageModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'family_id')
  final String familyId;
  @override
  @JsonKey(name: 'sender_id')
  final String senderId;
  @override
  final String content;
  @override
  @JsonKey(name: 'media_url')
  final String? mediaUrl;
  @override
  @JsonKey(name: 'channel_id')
  final String channelId;
  @override
  @JsonKey(name: 'channel_type')
  final String channelType;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  final List<ReactionModel> _reactions;
  @override
  @JsonKey(name: 'message_reactions')
  List<ReactionModel> get reactions {
    if (_reactions is EqualUnmodifiableListView) return _reactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reactions);
  }

  final List<ReadReceiptModel> _reads;
  @override
  @JsonKey(name: 'message_reads')
  List<ReadReceiptModel> get reads {
    if (_reads is EqualUnmodifiableListView) return _reads;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_reads);
  }

  @override
  String toString() {
    return 'MessageModel(id: $id, familyId: $familyId, senderId: $senderId, content: $content, mediaUrl: $mediaUrl, channelId: $channelId, channelType: $channelType, createdAt: $createdAt, updatedAt: $updatedAt, reactions: $reactions, reads: $reads)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MessageModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.mediaUrl, mediaUrl) ||
                other.mediaUrl == mediaUrl) &&
            (identical(other.channelId, channelId) ||
                other.channelId == channelId) &&
            (identical(other.channelType, channelType) ||
                other.channelType == channelType) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(
              other._reactions,
              _reactions,
            ) &&
            const DeepCollectionEquality().equals(other._reads, _reads));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    senderId,
    content,
    mediaUrl,
    channelId,
    channelType,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_reactions),
    const DeepCollectionEquality().hash(_reads),
  );

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      __$$MessageModelImplCopyWithImpl<_$MessageModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MessageModelImplToJson(this);
  }
}

abstract class _MessageModel implements MessageModel {
  const factory _MessageModel({
    required final String id,
    @JsonKey(name: 'family_id') required final String familyId,
    @JsonKey(name: 'sender_id') required final String senderId,
    required final String content,
    @JsonKey(name: 'media_url') final String? mediaUrl,
    @JsonKey(name: 'channel_id') final String channelId,
    @JsonKey(name: 'channel_type') final String channelType,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'message_reactions') final List<ReactionModel> reactions,
    @JsonKey(name: 'message_reads') final List<ReadReceiptModel> reads,
  }) = _$MessageModelImpl;

  factory _MessageModel.fromJson(Map<String, dynamic> json) =
      _$MessageModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'family_id')
  String get familyId;
  @override
  @JsonKey(name: 'sender_id')
  String get senderId;
  @override
  String get content;
  @override
  @JsonKey(name: 'media_url')
  String? get mediaUrl;
  @override
  @JsonKey(name: 'channel_id')
  String get channelId;
  @override
  @JsonKey(name: 'channel_type')
  String get channelType;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'message_reactions')
  List<ReactionModel> get reactions;
  @override
  @JsonKey(name: 'message_reads')
  List<ReadReceiptModel> get reads;

  /// Create a copy of MessageModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MessageModelImplCopyWith<_$MessageModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
