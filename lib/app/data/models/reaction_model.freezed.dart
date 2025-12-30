// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reaction_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReactionModel _$ReactionModelFromJson(Map<String, dynamic> json) {
  return _ReactionModel.fromJson(json);
}

/// @nodoc
mixin _$ReactionModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_id')
  String get messageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ReactionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReactionModelCopyWith<ReactionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReactionModelCopyWith<$Res> {
  factory $ReactionModelCopyWith(
    ReactionModel value,
    $Res Function(ReactionModel) then,
  ) = _$ReactionModelCopyWithImpl<$Res, ReactionModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'message_id') String messageId,
    @JsonKey(name: 'user_id') String userId,
    String emoji,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$ReactionModelCopyWithImpl<$Res, $Val extends ReactionModel>
    implements $ReactionModelCopyWith<$Res> {
  _$ReactionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            messageId: null == messageId
                ? _value.messageId
                : messageId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            emoji: null == emoji
                ? _value.emoji
                : emoji // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReactionModelImplCopyWith<$Res>
    implements $ReactionModelCopyWith<$Res> {
  factory _$$ReactionModelImplCopyWith(
    _$ReactionModelImpl value,
    $Res Function(_$ReactionModelImpl) then,
  ) = __$$ReactionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'message_id') String messageId,
    @JsonKey(name: 'user_id') String userId,
    String emoji,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$ReactionModelImplCopyWithImpl<$Res>
    extends _$ReactionModelCopyWithImpl<$Res, _$ReactionModelImpl>
    implements _$$ReactionModelImplCopyWith<$Res> {
  __$$ReactionModelImplCopyWithImpl(
    _$ReactionModelImpl _value,
    $Res Function(_$ReactionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? emoji = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ReactionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        messageId: null == messageId
            ? _value.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        emoji: null == emoji
            ? _value.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReactionModelImpl implements _ReactionModel {
  const _$ReactionModelImpl({
    required this.id,
    @JsonKey(name: 'message_id') required this.messageId,
    @JsonKey(name: 'user_id') required this.userId,
    required this.emoji,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$ReactionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReactionModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'message_id')
  final String messageId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  final String emoji;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ReactionModel(id: $id, messageId: $messageId, userId: $userId, emoji: $emoji, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReactionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, messageId, userId, emoji, createdAt);

  /// Create a copy of ReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReactionModelImplCopyWith<_$ReactionModelImpl> get copyWith =>
      __$$ReactionModelImplCopyWithImpl<_$ReactionModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReactionModelImplToJson(this);
  }
}

abstract class _ReactionModel implements ReactionModel {
  const factory _ReactionModel({
    required final String id,
    @JsonKey(name: 'message_id') required final String messageId,
    @JsonKey(name: 'user_id') required final String userId,
    required final String emoji,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$ReactionModelImpl;

  factory _ReactionModel.fromJson(Map<String, dynamic> json) =
      _$ReactionModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'message_id')
  String get messageId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  String get emoji;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ReactionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReactionModelImplCopyWith<_$ReactionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
