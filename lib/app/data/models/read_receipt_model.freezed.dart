// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'read_receipt_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReadReceiptModel _$ReadReceiptModelFromJson(Map<String, dynamic> json) {
  return _ReadReceiptModel.fromJson(json);
}

/// @nodoc
mixin _$ReadReceiptModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'message_id')
  String get messageId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ReadReceiptModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReadReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReadReceiptModelCopyWith<ReadReceiptModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReadReceiptModelCopyWith<$Res> {
  factory $ReadReceiptModelCopyWith(
    ReadReceiptModel value,
    $Res Function(ReadReceiptModel) then,
  ) = _$ReadReceiptModelCopyWithImpl<$Res, ReadReceiptModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'message_id') String messageId,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$ReadReceiptModelCopyWithImpl<$Res, $Val extends ReadReceiptModel>
    implements $ReadReceiptModelCopyWith<$Res> {
  _$ReadReceiptModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReadReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
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
abstract class _$$ReadReceiptModelImplCopyWith<$Res>
    implements $ReadReceiptModelCopyWith<$Res> {
  factory _$$ReadReceiptModelImplCopyWith(
    _$ReadReceiptModelImpl value,
    $Res Function(_$ReadReceiptModelImpl) then,
  ) = __$$ReadReceiptModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'message_id') String messageId,
    @JsonKey(name: 'user_id') String userId,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$ReadReceiptModelImplCopyWithImpl<$Res>
    extends _$ReadReceiptModelCopyWithImpl<$Res, _$ReadReceiptModelImpl>
    implements _$$ReadReceiptModelImplCopyWith<$Res> {
  __$$ReadReceiptModelImplCopyWithImpl(
    _$ReadReceiptModelImpl _value,
    $Res Function(_$ReadReceiptModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReadReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? messageId = null,
    Object? userId = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ReadReceiptModelImpl(
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
class _$ReadReceiptModelImpl implements _ReadReceiptModel {
  const _$ReadReceiptModelImpl({
    required this.id,
    @JsonKey(name: 'message_id') required this.messageId,
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$ReadReceiptModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReadReceiptModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'message_id')
  final String messageId;
  @override
  @JsonKey(name: 'user_id')
  final String userId;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ReadReceiptModel(id: $id, messageId: $messageId, userId: $userId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReadReceiptModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, messageId, userId, createdAt);

  /// Create a copy of ReadReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReadReceiptModelImplCopyWith<_$ReadReceiptModelImpl> get copyWith =>
      __$$ReadReceiptModelImplCopyWithImpl<_$ReadReceiptModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ReadReceiptModelImplToJson(this);
  }
}

abstract class _ReadReceiptModel implements ReadReceiptModel {
  const factory _ReadReceiptModel({
    required final String id,
    @JsonKey(name: 'message_id') required final String messageId,
    @JsonKey(name: 'user_id') required final String userId,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$ReadReceiptModelImpl;

  factory _ReadReceiptModel.fromJson(Map<String, dynamic> json) =
      _$ReadReceiptModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'message_id')
  String get messageId;
  @override
  @JsonKey(name: 'user_id')
  String get userId;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ReadReceiptModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReadReceiptModelImplCopyWith<_$ReadReceiptModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
