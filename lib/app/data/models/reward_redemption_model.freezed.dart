// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reward_redemption_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RewardRedemptionModel _$RewardRedemptionModelFromJson(
  Map<String, dynamic> json,
) {
  return _RewardRedemptionModel.fromJson(json);
}

/// @nodoc
mixin _$RewardRedemptionModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get rewardId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get costAtRedemption => throw _privateConstructorUsedError;
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'approved', 'fulfilled', 'rejected'
  DateTime? get redeemedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt =>
      throw _privateConstructorUsedError; // Optional: Include joined Reward data for easy display
  String? get rewardTitle => throw _privateConstructorUsedError;
  String? get rewardIcon => throw _privateConstructorUsedError;
  String? get userName => throw _privateConstructorUsedError;

  /// Serializes this RewardRedemptionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RewardRedemptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RewardRedemptionModelCopyWith<RewardRedemptionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RewardRedemptionModelCopyWith<$Res> {
  factory $RewardRedemptionModelCopyWith(
    RewardRedemptionModel value,
    $Res Function(RewardRedemptionModel) then,
  ) = _$RewardRedemptionModelCopyWithImpl<$Res, RewardRedemptionModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String rewardId,
    String userId,
    int costAtRedemption,
    String status,
    DateTime? redeemedAt,
    DateTime? updatedAt,
    String? rewardTitle,
    String? rewardIcon,
    String? userName,
  });
}

/// @nodoc
class _$RewardRedemptionModelCopyWithImpl<
  $Res,
  $Val extends RewardRedemptionModel
>
    implements $RewardRedemptionModelCopyWith<$Res> {
  _$RewardRedemptionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RewardRedemptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? rewardId = null,
    Object? userId = null,
    Object? costAtRedemption = null,
    Object? status = null,
    Object? redeemedAt = freezed,
    Object? updatedAt = freezed,
    Object? rewardTitle = freezed,
    Object? rewardIcon = freezed,
    Object? userName = freezed,
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
            rewardId: null == rewardId
                ? _value.rewardId
                : rewardId // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            costAtRedemption: null == costAtRedemption
                ? _value.costAtRedemption
                : costAtRedemption // ignore: cast_nullable_to_non_nullable
                      as int,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            redeemedAt: freezed == redeemedAt
                ? _value.redeemedAt
                : redeemedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            rewardTitle: freezed == rewardTitle
                ? _value.rewardTitle
                : rewardTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            rewardIcon: freezed == rewardIcon
                ? _value.rewardIcon
                : rewardIcon // ignore: cast_nullable_to_non_nullable
                      as String?,
            userName: freezed == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RewardRedemptionModelImplCopyWith<$Res>
    implements $RewardRedemptionModelCopyWith<$Res> {
  factory _$$RewardRedemptionModelImplCopyWith(
    _$RewardRedemptionModelImpl value,
    $Res Function(_$RewardRedemptionModelImpl) then,
  ) = __$$RewardRedemptionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String rewardId,
    String userId,
    int costAtRedemption,
    String status,
    DateTime? redeemedAt,
    DateTime? updatedAt,
    String? rewardTitle,
    String? rewardIcon,
    String? userName,
  });
}

/// @nodoc
class __$$RewardRedemptionModelImplCopyWithImpl<$Res>
    extends
        _$RewardRedemptionModelCopyWithImpl<$Res, _$RewardRedemptionModelImpl>
    implements _$$RewardRedemptionModelImplCopyWith<$Res> {
  __$$RewardRedemptionModelImplCopyWithImpl(
    _$RewardRedemptionModelImpl _value,
    $Res Function(_$RewardRedemptionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RewardRedemptionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? rewardId = null,
    Object? userId = null,
    Object? costAtRedemption = null,
    Object? status = null,
    Object? redeemedAt = freezed,
    Object? updatedAt = freezed,
    Object? rewardTitle = freezed,
    Object? rewardIcon = freezed,
    Object? userName = freezed,
  }) {
    return _then(
      _$RewardRedemptionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        rewardId: null == rewardId
            ? _value.rewardId
            : rewardId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        costAtRedemption: null == costAtRedemption
            ? _value.costAtRedemption
            : costAtRedemption // ignore: cast_nullable_to_non_nullable
                  as int,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        redeemedAt: freezed == redeemedAt
            ? _value.redeemedAt
            : redeemedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        rewardTitle: freezed == rewardTitle
            ? _value.rewardTitle
            : rewardTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        rewardIcon: freezed == rewardIcon
            ? _value.rewardIcon
            : rewardIcon // ignore: cast_nullable_to_non_nullable
                  as String?,
        userName: freezed == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RewardRedemptionModelImpl implements _RewardRedemptionModel {
  const _$RewardRedemptionModelImpl({
    required this.id,
    required this.familyId,
    required this.rewardId,
    required this.userId,
    required this.costAtRedemption,
    this.status = 'pending',
    this.redeemedAt,
    this.updatedAt,
    this.rewardTitle,
    this.rewardIcon,
    this.userName,
  });

  factory _$RewardRedemptionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RewardRedemptionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String rewardId;
  @override
  final String userId;
  @override
  final int costAtRedemption;
  @override
  @JsonKey()
  final String status;
  // 'pending', 'approved', 'fulfilled', 'rejected'
  @override
  final DateTime? redeemedAt;
  @override
  final DateTime? updatedAt;
  // Optional: Include joined Reward data for easy display
  @override
  final String? rewardTitle;
  @override
  final String? rewardIcon;
  @override
  final String? userName;

  @override
  String toString() {
    return 'RewardRedemptionModel(id: $id, familyId: $familyId, rewardId: $rewardId, userId: $userId, costAtRedemption: $costAtRedemption, status: $status, redeemedAt: $redeemedAt, updatedAt: $updatedAt, rewardTitle: $rewardTitle, rewardIcon: $rewardIcon, userName: $userName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RewardRedemptionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.rewardId, rewardId) ||
                other.rewardId == rewardId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.costAtRedemption, costAtRedemption) ||
                other.costAtRedemption == costAtRedemption) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.redeemedAt, redeemedAt) ||
                other.redeemedAt == redeemedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.rewardTitle, rewardTitle) ||
                other.rewardTitle == rewardTitle) &&
            (identical(other.rewardIcon, rewardIcon) ||
                other.rewardIcon == rewardIcon) &&
            (identical(other.userName, userName) ||
                other.userName == userName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    rewardId,
    userId,
    costAtRedemption,
    status,
    redeemedAt,
    updatedAt,
    rewardTitle,
    rewardIcon,
    userName,
  );

  /// Create a copy of RewardRedemptionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RewardRedemptionModelImplCopyWith<_$RewardRedemptionModelImpl>
  get copyWith =>
      __$$RewardRedemptionModelImplCopyWithImpl<_$RewardRedemptionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RewardRedemptionModelImplToJson(this);
  }
}

abstract class _RewardRedemptionModel implements RewardRedemptionModel {
  const factory _RewardRedemptionModel({
    required final String id,
    required final String familyId,
    required final String rewardId,
    required final String userId,
    required final int costAtRedemption,
    final String status,
    final DateTime? redeemedAt,
    final DateTime? updatedAt,
    final String? rewardTitle,
    final String? rewardIcon,
    final String? userName,
  }) = _$RewardRedemptionModelImpl;

  factory _RewardRedemptionModel.fromJson(Map<String, dynamic> json) =
      _$RewardRedemptionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get rewardId;
  @override
  String get userId;
  @override
  int get costAtRedemption;
  @override
  String get status; // 'pending', 'approved', 'fulfilled', 'rejected'
  @override
  DateTime? get redeemedAt;
  @override
  DateTime? get updatedAt; // Optional: Include joined Reward data for easy display
  @override
  String? get rewardTitle;
  @override
  String? get rewardIcon;
  @override
  String? get userName;

  /// Create a copy of RewardRedemptionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RewardRedemptionModelImplCopyWith<_$RewardRedemptionModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
