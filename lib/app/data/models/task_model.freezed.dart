// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TaskModel _$TaskModelFromJson(Map<String, dynamic> json) {
  return _TaskModel.fromJson(json);
}

/// @nodoc
mixin _$TaskModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get assignedTo =>
      throw _privateConstructorUsedError; // User ID - matches schema
  String get createdBy =>
      throw _privateConstructorUsedError; // User ID who created the task
  String get status =>
      throw _privateConstructorUsedError; // 'pending', 'in_progress', 'completed'
  String get priority =>
      throw _privateConstructorUsedError; // 'low', 'medium', 'high'
  String get category =>
      throw _privateConstructorUsedError; // 'chore', 'grocery', 'event', etc.
  Map<String, dynamic>? get categoryData =>
      throw _privateConstructorUsedError; // Category-specific data (e.g., groceryListId)
  DateTime? get dueDate => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Serializes this TaskModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TaskModelCopyWith<TaskModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskModelCopyWith<$Res> {
  factory $TaskModelCopyWith(TaskModel value, $Res Function(TaskModel) then) =
      _$TaskModelCopyWithImpl<$Res, TaskModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String title,
    String? description,
    String assignedTo,
    String createdBy,
    String status,
    String priority,
    String category,
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int points,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class _$TaskModelCopyWithImpl<$Res, $Val extends TaskModel>
    implements $TaskModelCopyWith<$Res> {
  _$TaskModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? title = null,
    Object? description = freezed,
    Object? assignedTo = null,
    Object? createdBy = null,
    Object? status = null,
    Object? priority = null,
    Object? category = null,
    Object? categoryData = freezed,
    Object? dueDate = freezed,
    Object? points = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? completedAt = freezed,
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
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignedTo: null == assignedTo
                ? _value.assignedTo
                : assignedTo // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            priority: null == priority
                ? _value.priority
                : priority // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String,
            categoryData: freezed == categoryData
                ? _value.categoryData
                : categoryData // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TaskModelImplCopyWith<$Res>
    implements $TaskModelCopyWith<$Res> {
  factory _$$TaskModelImplCopyWith(
    _$TaskModelImpl value,
    $Res Function(_$TaskModelImpl) then,
  ) = __$$TaskModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String title,
    String? description,
    String assignedTo,
    String createdBy,
    String status,
    String priority,
    String category,
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int points,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  });
}

/// @nodoc
class __$$TaskModelImplCopyWithImpl<$Res>
    extends _$TaskModelCopyWithImpl<$Res, _$TaskModelImpl>
    implements _$$TaskModelImplCopyWith<$Res> {
  __$$TaskModelImplCopyWithImpl(
    _$TaskModelImpl _value,
    $Res Function(_$TaskModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? title = null,
    Object? description = freezed,
    Object? assignedTo = null,
    Object? createdBy = null,
    Object? status = null,
    Object? priority = null,
    Object? category = null,
    Object? categoryData = freezed,
    Object? dueDate = freezed,
    Object? points = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? completedAt = freezed,
  }) {
    return _then(
      _$TaskModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignedTo: null == assignedTo
            ? _value.assignedTo
            : assignedTo // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        priority: null == priority
            ? _value.priority
            : priority // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryData: freezed == categoryData
            ? _value._categoryData
            : categoryData // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskModelImpl implements _TaskModel {
  const _$TaskModelImpl({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.createdBy,
    this.status = 'pending',
    this.priority = 'medium',
    this.category = 'chore',
    final Map<String, dynamic>? categoryData,
    this.dueDate,
    this.points = 10,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  }) : _categoryData = categoryData;

  factory _$TaskModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String assignedTo;
  // User ID - matches schema
  @override
  final String createdBy;
  // User ID who created the task
  @override
  @JsonKey()
  final String status;
  // 'pending', 'in_progress', 'completed'
  @override
  @JsonKey()
  final String priority;
  // 'low', 'medium', 'high'
  @override
  @JsonKey()
  final String category;
  // 'chore', 'grocery', 'event', etc.
  final Map<String, dynamic>? _categoryData;
  // 'chore', 'grocery', 'event', etc.
  @override
  Map<String, dynamic>? get categoryData {
    final value = _categoryData;
    if (value == null) return null;
    if (_categoryData is EqualUnmodifiableMapView) return _categoryData;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  // Category-specific data (e.g., groceryListId)
  @override
  final DateTime? dueDate;
  @override
  @JsonKey()
  final int points;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? completedAt;

  @override
  String toString() {
    return 'TaskModel(id: $id, familyId: $familyId, title: $title, description: $description, assignedTo: $assignedTo, createdBy: $createdBy, status: $status, priority: $priority, category: $category, categoryData: $categoryData, dueDate: $dueDate, points: $points, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.assignedTo, assignedTo) ||
                other.assignedTo == assignedTo) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.priority, priority) ||
                other.priority == priority) &&
            (identical(other.category, category) ||
                other.category == category) &&
            const DeepCollectionEquality().equals(
              other._categoryData,
              _categoryData,
            ) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.points, points) || other.points == points) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    title,
    description,
    assignedTo,
    createdBy,
    status,
    priority,
    category,
    const DeepCollectionEquality().hash(_categoryData),
    dueDate,
    points,
    createdAt,
    updatedAt,
    completedAt,
  );

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      __$$TaskModelImplCopyWithImpl<_$TaskModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskModelImplToJson(this);
  }
}

abstract class _TaskModel implements TaskModel {
  const factory _TaskModel({
    required final String id,
    required final String familyId,
    required final String title,
    final String? description,
    required final String assignedTo,
    required final String createdBy,
    final String status,
    final String priority,
    final String category,
    final Map<String, dynamic>? categoryData,
    final DateTime? dueDate,
    final int points,
    final DateTime? createdAt,
    final DateTime? updatedAt,
    final DateTime? completedAt,
  }) = _$TaskModelImpl;

  factory _TaskModel.fromJson(Map<String, dynamic> json) =
      _$TaskModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get title;
  @override
  String? get description;
  @override
  String get assignedTo; // User ID - matches schema
  @override
  String get createdBy; // User ID who created the task
  @override
  String get status; // 'pending', 'in_progress', 'completed'
  @override
  String get priority; // 'low', 'medium', 'high'
  @override
  String get category; // 'chore', 'grocery', 'event', etc.
  @override
  Map<String, dynamic>? get categoryData; // Category-specific data (e.g., groceryListId)
  @override
  DateTime? get dueDate;
  @override
  int get points;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  DateTime? get completedAt;

  /// Create a copy of TaskModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TaskModelImplCopyWith<_$TaskModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
