// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_template_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskTemplateModel _$TaskTemplateModelFromJson(Map<String, dynamic> json) {
  return _TaskTemplateModel.fromJson(json);
}

/// @nodoc
mixin _$TaskTemplateModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get priority => throw _privateConstructorUsedError;
  int? get points => throw _privateConstructorUsedError;
  String? get recurrenceType => throw _privateConstructorUsedError;
  DateTime? get recurrenceEndDate => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this TaskTemplateModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskTemplateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskTemplateModelCopyWith<TaskTemplateModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskTemplateModelCopyWith<$Res> {
  factory $TaskTemplateModelCopyWith(
    TaskTemplateModel value,
    $Res Function(TaskTemplateModel) then,
  ) = _$TaskTemplateModelCopyWithImpl<$Res, TaskTemplateModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String name,
    String title,
    String? description,
    String? category,
    String? priority,
    int? points,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$TaskTemplateModelCopyWithImpl<$Res, $Val extends TaskTemplateModel>
    implements $TaskTemplateModelCopyWith<$Res> {
  _$TaskTemplateModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskTemplateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? name = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? priority = freezed,
    Object? points = freezed,
    Object? recurrenceType = freezed,
    Object? recurrenceEndDate = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
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
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            priority: freezed == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String?,
            points: freezed == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int?,
            recurrenceType: freezed == recurrenceType
                ? _value.recurrenceType
                : recurrenceType // ignore: cast_nullable_to_non_nullable
                      as String?,
            recurrenceEndDate: freezed == recurrenceEndDate
                ? _value.recurrenceEndDate
                : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskTemplateModelImplCopyWith<$Res>
    implements $TaskTemplateModelCopyWith<$Res> {
  factory _$$TaskTemplateModelImplCopyWith(
    _$TaskTemplateModelImpl value,
    $Res Function(_$TaskTemplateModelImpl) then,
  ) = __$$TaskTemplateModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String name,
    String title,
    String? description,
    String? category,
    String? priority,
    int? points,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$TaskTemplateModelImplCopyWithImpl<$Res>
    extends _$TaskTemplateModelCopyWithImpl<$Res, _$TaskTemplateModelImpl>
    implements _$$TaskTemplateModelImplCopyWith<$Res> {
  __$$TaskTemplateModelImplCopyWithImpl(
    _$TaskTemplateModelImpl _value,
    $Res Function(_$TaskTemplateModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskTemplateModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? name = null,
    Object? title = null,
    Object? description = freezed,
    Object? category = freezed,
    Object? priority = freezed,
    Object? points = freezed,
    Object? recurrenceType = freezed,
    Object? recurrenceEndDate = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$TaskTemplateModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        priority: freezed == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String?,
        points: freezed == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int?,
        recurrenceType: freezed == recurrenceType
            ? _value.recurrenceType
            : recurrenceType // ignore: cast_nullable_to_non_nullable
                  as String?,
        recurrenceEndDate: freezed == recurrenceEndDate
            ? _value.recurrenceEndDate
            : recurrenceEndDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskTemplateModelImpl implements _TaskTemplateModel {
  const _$TaskTemplateModelImpl({
    required this.id,
    required this.familyId,
    required this.name,
    required this.title,
    this.description,
    this.category,
    this.priority,
    this.points,
    this.recurrenceType,
    this.recurrenceEndDate,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory _$TaskTemplateModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskTemplateModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String name;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? category;
  @override
  final String? priority;
  @override
  final int? points;
  @override
  final String? recurrenceType;
  @override
  final DateTime? recurrenceEndDate;
  @override
  final String createdBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'TaskTemplateModel(id: $id, familyId: $familyId, name: $name, title: $title, description: $description, category: $category, priority: $priority, points: $points, recurrenceType: $recurrenceType, recurrenceEndDate: $recurrenceEndDate, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskTemplateModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.recurrenceType, recurrenceType) ||
                other.recurrenceType == recurrenceType) &&
            (identical(other.recurrenceEndDate, recurrenceEndDate) ||
                other.recurrenceEndDate == recurrenceEndDate) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    name,
    title,
    description,
    category,
    priority,
    points,
    recurrenceType,
    recurrenceEndDate,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of TaskTemplateModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskTemplateModelImplCopyWith<_$TaskTemplateModelImpl> get copyWith =>
      __$$TaskTemplateModelImplCopyWithImpl<_$TaskTemplateModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskTemplateModelImplToJson(this);
  }
}

abstract class _TaskTemplateModel implements TaskTemplateModel {
  const factory _TaskTemplateModel({
    required final String id,
    required final String familyId,
    required final String name,
    required final String title,
    final String? description,
    final String? category,
    final String? priority,
    final int? points,
    final String? recurrenceType,
    final DateTime? recurrenceEndDate,
    required final String createdBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$TaskTemplateModelImpl;

  factory _TaskTemplateModel.fromJson(Map<String, dynamic> json) =
      _$TaskTemplateModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get name;
  @override
  String get title;
  @override
  String? get description;
  @override
  String? get category;
  @override
  String? get priority;
  @override
  int? get points;
  @override
  String? get recurrenceType;
  @override
  DateTime? get recurrenceEndDate;
  @override
  String get createdBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of TaskTemplateModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskTemplateModelImplCopyWith<_$TaskTemplateModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
