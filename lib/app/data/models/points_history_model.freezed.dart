// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'points_history_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PointsHistoryModel _$PointsHistoryModelFromJson(Map<String, dynamic> json) {
  return _PointsHistoryModel.fromJson(json);
}

/// @nodoc
mixin _$PointsHistoryModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  int get points =>
      throw _privateConstructorUsedError; // Can be positive (awarded) or negative (removed)
  String get reason =>
      throw _privateConstructorUsedError; // e.g., 'task_completed', 'task_uncompleted', 'bonus', etc.
  String? get taskId =>
      throw _privateConstructorUsedError; // Reference to task if points are from task completion
  String? get taskTitle =>
      throw _privateConstructorUsedError; // Task title for display
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this PointsHistoryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PointsHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PointsHistoryModelCopyWith<PointsHistoryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PointsHistoryModelCopyWith<$Res> {
  factory $PointsHistoryModelCopyWith(
    PointsHistoryModel value,
    $Res Function(PointsHistoryModel) then,
  ) = _$PointsHistoryModelCopyWithImpl<$Res, PointsHistoryModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String userId,
    int points,
    String reason,
    String? taskId,
    String? taskTitle,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$PointsHistoryModelCopyWithImpl<$Res, $Val extends PointsHistoryModel>
    implements $PointsHistoryModelCopyWith<$Res> {
  _$PointsHistoryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PointsHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? userId = null,
    Object? points = null,
    Object? reason = null,
    Object? taskId = freezed,
    Object? taskTitle = freezed,
    Object? createdAt = freezed,
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
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            taskId: freezed == taskId
                ? _value.taskId
                : taskId // ignore: cast_nullable_to_non_nullable
                      as String?,
            taskTitle: freezed == taskTitle
                ? _value.taskTitle
                : taskTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PointsHistoryModelImplCopyWith<$Res>
    implements $PointsHistoryModelCopyWith<$Res> {
  factory _$$PointsHistoryModelImplCopyWith(
    _$PointsHistoryModelImpl value,
    $Res Function(_$PointsHistoryModelImpl) then,
  ) = __$$PointsHistoryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String userId,
    int points,
    String reason,
    String? taskId,
    String? taskTitle,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$PointsHistoryModelImplCopyWithImpl<$Res>
    extends _$PointsHistoryModelCopyWithImpl<$Res, _$PointsHistoryModelImpl>
    implements _$$PointsHistoryModelImplCopyWith<$Res> {
  __$$PointsHistoryModelImplCopyWithImpl(
    _$PointsHistoryModelImpl _value,
    $Res Function(_$PointsHistoryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PointsHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? userId = null,
    Object? points = null,
    Object? reason = null,
    Object? taskId = freezed,
    Object? taskTitle = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$PointsHistoryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        taskId: freezed == taskId
            ? _value.taskId
            : taskId // ignore: cast_nullable_to_non_nullable
                  as String?,
        taskTitle: freezed == taskTitle
            ? _value.taskTitle
            : taskTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PointsHistoryModelImpl implements _PointsHistoryModel {
  const _$PointsHistoryModelImpl({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.points,
    required this.reason,
    this.taskId,
    this.taskTitle,
    this.createdAt,
  });

  factory _$PointsHistoryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PointsHistoryModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String userId;
  @override
  final int points;
  // Can be positive (awarded) or negative (removed)
  @override
  final String reason;
  // e.g., 'task_completed', 'task_uncompleted', 'bonus', etc.
  @override
  final String? taskId;
  // Reference to task if points are from task completion
  @override
  final String? taskTitle;
  // Task title for display
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'PointsHistoryModel(id: $id, familyId: $familyId, userId: $userId, points: $points, reason: $reason, taskId: $taskId, taskTitle: $taskTitle, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PointsHistoryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.taskId, taskId) || other.taskId == taskId) &&
            (identical(other.taskTitle, taskTitle) ||
                other.taskTitle == taskTitle) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    userId,
    points,
    reason,
    taskId,
    taskTitle,
    createdAt,
  );

  /// Create a copy of PointsHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PointsHistoryModelImplCopyWith<_$PointsHistoryModelImpl> get copyWith =>
      __$$PointsHistoryModelImplCopyWithImpl<_$PointsHistoryModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PointsHistoryModelImplToJson(this);
  }
}

abstract class _PointsHistoryModel implements PointsHistoryModel {
  const factory _PointsHistoryModel({
    required final String id,
    required final String familyId,
    required final String userId,
    required final int points,
    required final String reason,
    final String? taskId,
    final String? taskTitle,
    final DateTime? createdAt,
  }) = _$PointsHistoryModelImpl;

  factory _PointsHistoryModel.fromJson(Map<String, dynamic> json) =
      _$PointsHistoryModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get userId;
  @override
  int get points; // Can be positive (awarded) or negative (removed)
  @override
  String get reason; // e.g., 'task_completed', 'task_uncompleted', 'bonus', etc.
  @override
  String? get taskId; // Reference to task if points are from task completion
  @override
  String? get taskTitle; // Task title for display
  @override
  DateTime? get createdAt;

  /// Create a copy of PointsHistoryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PointsHistoryModelImplCopyWith<_$PointsHistoryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
