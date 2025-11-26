// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'achievement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AchievementModel _$AchievementModelFromJson(Map<String, dynamic> json) {
  return _AchievementModel.fromJson(json);
}

/// @nodoc
mixin _$AchievementModel {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get achievementId =>
      throw _privateConstructorUsedError; // Reference to achievement definition
  DateTime get unlockedAt => throw _privateConstructorUsedError;

  /// Serializes this AchievementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AchievementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AchievementModelCopyWith<AchievementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AchievementModelCopyWith<$Res> {
  factory $AchievementModelCopyWith(
    AchievementModel value,
    $Res Function(AchievementModel) then,
  ) = _$AchievementModelCopyWithImpl<$Res, AchievementModel>;
  @useResult
  $Res call({
    String id,
    String userId,
    String familyId,
    String achievementId,
    DateTime unlockedAt,
  });
}

/// @nodoc
class _$AchievementModelCopyWithImpl<$Res, $Val extends AchievementModel>
    implements $AchievementModelCopyWith<$Res> {
  _$AchievementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AchievementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? familyId = null,
    Object? achievementId = null,
    Object? unlockedAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            familyId: null == familyId
                ? _value.familyId
                : familyId // ignore: cast_nullable_to_non_nullable
                      as String,
            achievementId: null == achievementId
                ? _value.achievementId
                : achievementId // ignore: cast_nullable_to_non_nullable
                      as String,
            unlockedAt: null == unlockedAt
                ? _value.unlockedAt
                : unlockedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AchievementModelImplCopyWith<$Res>
    implements $AchievementModelCopyWith<$Res> {
  factory _$$AchievementModelImplCopyWith(
    _$AchievementModelImpl value,
    $Res Function(_$AchievementModelImpl) then,
  ) = __$$AchievementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String userId,
    String familyId,
    String achievementId,
    DateTime unlockedAt,
  });
}

/// @nodoc
class __$$AchievementModelImplCopyWithImpl<$Res>
    extends _$AchievementModelCopyWithImpl<$Res, _$AchievementModelImpl>
    implements _$$AchievementModelImplCopyWith<$Res> {
  __$$AchievementModelImplCopyWithImpl(
    _$AchievementModelImpl _value,
    $Res Function(_$AchievementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AchievementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? familyId = null,
    Object? achievementId = null,
    Object? unlockedAt = null,
  }) {
    return _then(
      _$AchievementModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        achievementId: null == achievementId
            ? _value.achievementId
            : achievementId // ignore: cast_nullable_to_non_nullable
                  as String,
        unlockedAt: null == unlockedAt
            ? _value.unlockedAt
            : unlockedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AchievementModelImpl implements _AchievementModel {
  const _$AchievementModelImpl({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.achievementId,
    required this.unlockedAt,
  });

  factory _$AchievementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AchievementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String familyId;
  @override
  final String achievementId;
  // Reference to achievement definition
  @override
  final DateTime unlockedAt;

  @override
  String toString() {
    return 'AchievementModel(id: $id, userId: $userId, familyId: $familyId, achievementId: $achievementId, unlockedAt: $unlockedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AchievementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.achievementId, achievementId) ||
                other.achievementId == achievementId) &&
            (identical(other.unlockedAt, unlockedAt) ||
                other.unlockedAt == unlockedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, userId, familyId, achievementId, unlockedAt);

  /// Create a copy of AchievementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AchievementModelImplCopyWith<_$AchievementModelImpl> get copyWith =>
      __$$AchievementModelImplCopyWithImpl<_$AchievementModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AchievementModelImplToJson(this);
  }
}

abstract class _AchievementModel implements AchievementModel {
  const factory _AchievementModel({
    required final String id,
    required final String userId,
    required final String familyId,
    required final String achievementId,
    required final DateTime unlockedAt,
  }) = _$AchievementModelImpl;

  factory _AchievementModel.fromJson(Map<String, dynamic> json) =
      _$AchievementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get familyId;
  @override
  String get achievementId; // Reference to achievement definition
  @override
  DateTime get unlockedAt;

  /// Create a copy of AchievementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AchievementModelImplCopyWith<_$AchievementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
