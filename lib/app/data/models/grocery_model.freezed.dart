// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'grocery_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

GroceryMasterModel _$GroceryMasterModelFromJson(Map<String, dynamic> json) {
  return _GroceryMasterModel.fromJson(json);
}

/// @nodoc
mixin _$GroceryMasterModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get store => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GroceryMasterModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryMasterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryMasterModelCopyWith<GroceryMasterModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryMasterModelCopyWith<$Res> {
  factory $GroceryMasterModelCopyWith(
    GroceryMasterModel value,
    $Res Function(GroceryMasterModel) then,
  ) = _$GroceryMasterModelCopyWithImpl<$Res, GroceryMasterModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String name,
    String? store,
    String? description,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$GroceryMasterModelCopyWithImpl<$Res, $Val extends GroceryMasterModel>
    implements $GroceryMasterModelCopyWith<$Res> {
  _$GroceryMasterModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryMasterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? name = null,
    Object? store = freezed,
    Object? description = freezed,
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
            store: freezed == store
                ? _value.store
                : store // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$GroceryMasterModelImplCopyWith<$Res>
    implements $GroceryMasterModelCopyWith<$Res> {
  factory _$$GroceryMasterModelImplCopyWith(
    _$GroceryMasterModelImpl value,
    $Res Function(_$GroceryMasterModelImpl) then,
  ) = __$$GroceryMasterModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String name,
    String? store,
    String? description,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$GroceryMasterModelImplCopyWithImpl<$Res>
    extends _$GroceryMasterModelCopyWithImpl<$Res, _$GroceryMasterModelImpl>
    implements _$$GroceryMasterModelImplCopyWith<$Res> {
  __$$GroceryMasterModelImplCopyWithImpl(
    _$GroceryMasterModelImpl _value,
    $Res Function(_$GroceryMasterModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryMasterModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? name = null,
    Object? store = freezed,
    Object? description = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$GroceryMasterModelImpl(
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
        store: freezed == store
            ? _value.store
            : store // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$GroceryMasterModelImpl implements _GroceryMasterModel {
  const _$GroceryMasterModelImpl({
    required this.id,
    required this.familyId,
    required this.name,
    this.store,
    this.description,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory _$GroceryMasterModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryMasterModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String name;
  @override
  final String? store;
  @override
  final String? description;
  @override
  final String createdBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'GroceryMasterModel(id: $id, familyId: $familyId, name: $name, store: $store, description: $description, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryMasterModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.store, store) || other.store == store) &&
            (identical(other.description, description) ||
                other.description == description) &&
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
    store,
    description,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of GroceryMasterModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryMasterModelImplCopyWith<_$GroceryMasterModelImpl> get copyWith =>
      __$$GroceryMasterModelImplCopyWithImpl<_$GroceryMasterModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryMasterModelImplToJson(this);
  }
}

abstract class _GroceryMasterModel implements GroceryMasterModel {
  const factory _GroceryMasterModel({
    required final String id,
    required final String familyId,
    required final String name,
    final String? store,
    final String? description,
    required final String createdBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$GroceryMasterModelImpl;

  factory _GroceryMasterModel.fromJson(Map<String, dynamic> json) =
      _$GroceryMasterModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get name;
  @override
  String? get store;
  @override
  String? get description;
  @override
  String get createdBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of GroceryMasterModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryMasterModelImplCopyWith<_$GroceryMasterModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroceryMasterItemModel _$GroceryMasterItemModelFromJson(
  Map<String, dynamic> json,
) {
  return _GroceryMasterItemModel.fromJson(json);
}

/// @nodoc
mixin _$GroceryMasterItemModel {
  String get id => throw _privateConstructorUsedError;
  String get masterId => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GroceryItemCategory get category => throw _privateConstructorUsedError;
  int get defaultQty => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GroceryMasterItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryMasterItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryMasterItemModelCopyWith<GroceryMasterItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryMasterItemModelCopyWith<$Res> {
  factory $GroceryMasterItemModelCopyWith(
    GroceryMasterItemModel value,
    $Res Function(GroceryMasterItemModel) then,
  ) = _$GroceryMasterItemModelCopyWithImpl<$Res, GroceryMasterItemModel>;
  @useResult
  $Res call({
    String id,
    String masterId,
    String familyId,
    String name,
    GroceryItemCategory category,
    int defaultQty,
    String? notes,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$GroceryMasterItemModelCopyWithImpl<
  $Res,
  $Val extends GroceryMasterItemModel
>
    implements $GroceryMasterItemModelCopyWith<$Res> {
  _$GroceryMasterItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryMasterItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? masterId = null,
    Object? familyId = null,
    Object? name = null,
    Object? category = null,
    Object? defaultQty = null,
    Object? notes = freezed,
    Object? unit = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            masterId: null == masterId
                ? _value.masterId
                : masterId // ignore: cast_nullable_to_non_nullable
                      as String,
            familyId: null == familyId
                ? _value.familyId
                : familyId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as GroceryItemCategory,
            defaultQty: null == defaultQty
                ? _value.defaultQty
                : defaultQty // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
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
abstract class _$$GroceryMasterItemModelImplCopyWith<$Res>
    implements $GroceryMasterItemModelCopyWith<$Res> {
  factory _$$GroceryMasterItemModelImplCopyWith(
    _$GroceryMasterItemModelImpl value,
    $Res Function(_$GroceryMasterItemModelImpl) then,
  ) = __$$GroceryMasterItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String masterId,
    String familyId,
    String name,
    GroceryItemCategory category,
    int defaultQty,
    String? notes,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$GroceryMasterItemModelImplCopyWithImpl<$Res>
    extends
        _$GroceryMasterItemModelCopyWithImpl<$Res, _$GroceryMasterItemModelImpl>
    implements _$$GroceryMasterItemModelImplCopyWith<$Res> {
  __$$GroceryMasterItemModelImplCopyWithImpl(
    _$GroceryMasterItemModelImpl _value,
    $Res Function(_$GroceryMasterItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryMasterItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? masterId = null,
    Object? familyId = null,
    Object? name = null,
    Object? category = null,
    Object? defaultQty = null,
    Object? notes = freezed,
    Object? unit = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$GroceryMasterItemModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        masterId: null == masterId
            ? _value.masterId
            : masterId // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as GroceryItemCategory,
        defaultQty: null == defaultQty
            ? _value.defaultQty
            : defaultQty // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
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
class _$GroceryMasterItemModelImpl implements _GroceryMasterItemModel {
  const _$GroceryMasterItemModelImpl({
    required this.id,
    required this.masterId,
    required this.familyId,
    required this.name,
    required this.category,
    this.defaultQty = 1,
    this.notes,
    this.unit,
    this.createdAt,
    this.updatedAt,
  });

  factory _$GroceryMasterItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryMasterItemModelImplFromJson(json);

  @override
  final String id;
  @override
  final String masterId;
  @override
  final String familyId;
  @override
  final String name;
  @override
  final GroceryItemCategory category;
  @override
  @JsonKey()
  final int defaultQty;
  @override
  final String? notes;
  @override
  final String? unit;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'GroceryMasterItemModel(id: $id, masterId: $masterId, familyId: $familyId, name: $name, category: $category, defaultQty: $defaultQty, notes: $notes, unit: $unit, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryMasterItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.masterId, masterId) ||
                other.masterId == masterId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.defaultQty, defaultQty) ||
                other.defaultQty == defaultQty) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.unit, unit) || other.unit == unit) &&
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
    masterId,
    familyId,
    name,
    category,
    defaultQty,
    notes,
    unit,
    createdAt,
    updatedAt,
  );

  /// Create a copy of GroceryMasterItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryMasterItemModelImplCopyWith<_$GroceryMasterItemModelImpl>
  get copyWith =>
      __$$GroceryMasterItemModelImplCopyWithImpl<_$GroceryMasterItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryMasterItemModelImplToJson(this);
  }
}

abstract class _GroceryMasterItemModel implements GroceryMasterItemModel {
  const factory _GroceryMasterItemModel({
    required final String id,
    required final String masterId,
    required final String familyId,
    required final String name,
    required final GroceryItemCategory category,
    final int defaultQty,
    final String? notes,
    final String? unit,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$GroceryMasterItemModelImpl;

  factory _GroceryMasterItemModel.fromJson(Map<String, dynamic> json) =
      _$GroceryMasterItemModelImpl.fromJson;

  @override
  String get id;
  @override
  String get masterId;
  @override
  String get familyId;
  @override
  String get name;
  @override
  GroceryItemCategory get category;
  @override
  int get defaultQty;
  @override
  String? get notes;
  @override
  String? get unit;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of GroceryMasterItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryMasterItemModelImplCopyWith<_$GroceryMasterItemModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

GroceryTripModel _$GroceryTripModelFromJson(Map<String, dynamic> json) {
  return _GroceryTripModel.fromJson(json);
}

/// @nodoc
mixin _$GroceryTripModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String? get masterId => throw _privateConstructorUsedError;
  String get assignee => throw _privateConstructorUsedError;
  String? get store => throw _privateConstructorUsedError;
  GroceryTripStatus get status => throw _privateConstructorUsedError;
  DateTime? get startedAt => throw _privateConstructorUsedError;
  DateTime? get completedAt => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GroceryTripModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryTripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryTripModelCopyWith<GroceryTripModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryTripModelCopyWith<$Res> {
  factory $GroceryTripModelCopyWith(
    GroceryTripModel value,
    $Res Function(GroceryTripModel) then,
  ) = _$GroceryTripModelCopyWithImpl<$Res, GroceryTripModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String? masterId,
    String assignee,
    String? store,
    GroceryTripStatus status,
    DateTime? startedAt,
    DateTime? completedAt,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$GroceryTripModelCopyWithImpl<$Res, $Val extends GroceryTripModel>
    implements $GroceryTripModelCopyWith<$Res> {
  _$GroceryTripModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryTripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? masterId = freezed,
    Object? assignee = null,
    Object? store = freezed,
    Object? status = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
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
            masterId: freezed == masterId
                ? _value.masterId
                : masterId // ignore: cast_nullable_to_non_nullable
                      as String?,
            assignee: null == assignee
                ? _value.assignee
                : assignee // ignore: cast_nullable_to_non_nullable
                      as String,
            store: freezed == store
                ? _value.store
                : store // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as GroceryTripStatus,
            startedAt: freezed == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            completedAt: freezed == completedAt
                ? _value.completedAt
                : completedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$GroceryTripModelImplCopyWith<$Res>
    implements $GroceryTripModelCopyWith<$Res> {
  factory _$$GroceryTripModelImplCopyWith(
    _$GroceryTripModelImpl value,
    $Res Function(_$GroceryTripModelImpl) then,
  ) = __$$GroceryTripModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String? masterId,
    String assignee,
    String? store,
    GroceryTripStatus status,
    DateTime? startedAt,
    DateTime? completedAt,
    String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$GroceryTripModelImplCopyWithImpl<$Res>
    extends _$GroceryTripModelCopyWithImpl<$Res, _$GroceryTripModelImpl>
    implements _$$GroceryTripModelImplCopyWith<$Res> {
  __$$GroceryTripModelImplCopyWithImpl(
    _$GroceryTripModelImpl _value,
    $Res Function(_$GroceryTripModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryTripModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? masterId = freezed,
    Object? assignee = null,
    Object? store = freezed,
    Object? status = null,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? createdBy = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$GroceryTripModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        masterId: freezed == masterId
            ? _value.masterId
            : masterId // ignore: cast_nullable_to_non_nullable
                  as String?,
        assignee: null == assignee
            ? _value.assignee
            : assignee // ignore: cast_nullable_to_non_nullable
                  as String,
        store: freezed == store
            ? _value.store
            : store // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as GroceryTripStatus,
        startedAt: freezed == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        completedAt: freezed == completedAt
            ? _value.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
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
class _$GroceryTripModelImpl implements _GroceryTripModel {
  const _$GroceryTripModelImpl({
    required this.id,
    required this.familyId,
    this.masterId,
    required this.assignee,
    this.store,
    this.status = GroceryTripStatus.pending,
    this.startedAt,
    this.completedAt,
    required this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory _$GroceryTripModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryTripModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String? masterId;
  @override
  final String assignee;
  @override
  final String? store;
  @override
  @JsonKey()
  final GroceryTripStatus status;
  @override
  final DateTime? startedAt;
  @override
  final DateTime? completedAt;
  @override
  final String createdBy;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'GroceryTripModel(id: $id, familyId: $familyId, masterId: $masterId, assignee: $assignee, store: $store, status: $status, startedAt: $startedAt, completedAt: $completedAt, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryTripModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.masterId, masterId) ||
                other.masterId == masterId) &&
            (identical(other.assignee, assignee) ||
                other.assignee == assignee) &&
            (identical(other.store, store) || other.store == store) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
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
    masterId,
    assignee,
    store,
    status,
    startedAt,
    completedAt,
    createdBy,
    createdAt,
    updatedAt,
  );

  /// Create a copy of GroceryTripModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryTripModelImplCopyWith<_$GroceryTripModelImpl> get copyWith =>
      __$$GroceryTripModelImplCopyWithImpl<_$GroceryTripModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryTripModelImplToJson(this);
  }
}

abstract class _GroceryTripModel implements GroceryTripModel {
  const factory _GroceryTripModel({
    required final String id,
    required final String familyId,
    final String? masterId,
    required final String assignee,
    final String? store,
    final GroceryTripStatus status,
    final DateTime? startedAt,
    final DateTime? completedAt,
    required final String createdBy,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$GroceryTripModelImpl;

  factory _GroceryTripModel.fromJson(Map<String, dynamic> json) =
      _$GroceryTripModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String? get masterId;
  @override
  String get assignee;
  @override
  String? get store;
  @override
  GroceryTripStatus get status;
  @override
  DateTime? get startedAt;
  @override
  DateTime? get completedAt;
  @override
  String get createdBy;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of GroceryTripModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryTripModelImplCopyWith<_$GroceryTripModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GroceryTripItemModel _$GroceryTripItemModelFromJson(Map<String, dynamic> json) {
  return _GroceryTripItemModel.fromJson(json);
}

/// @nodoc
mixin _$GroceryTripItemModel {
  String get id => throw _privateConstructorUsedError;
  String get tripId => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  GroceryItemCategory get category => throw _privateConstructorUsedError;
  int get qty => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  bool get checked => throw _privateConstructorUsedError;
  DateTime? get checkedAt => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this GroceryTripItemModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GroceryTripItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GroceryTripItemModelCopyWith<GroceryTripItemModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryTripItemModelCopyWith<$Res> {
  factory $GroceryTripItemModelCopyWith(
    GroceryTripItemModel value,
    $Res Function(GroceryTripItemModel) then,
  ) = _$GroceryTripItemModelCopyWithImpl<$Res, GroceryTripItemModel>;
  @useResult
  $Res call({
    String id,
    String tripId,
    String familyId,
    String name,
    GroceryItemCategory category,
    int qty,
    String? notes,
    String? unit,
    bool checked,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$GroceryTripItemModelCopyWithImpl<
  $Res,
  $Val extends GroceryTripItemModel
>
    implements $GroceryTripItemModelCopyWith<$Res> {
  _$GroceryTripItemModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GroceryTripItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? familyId = null,
    Object? name = null,
    Object? category = null,
    Object? qty = null,
    Object? notes = freezed,
    Object? unit = freezed,
    Object? checked = null,
    Object? checkedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            tripId: null == tripId
                ? _value.tripId
                : tripId // ignore: cast_nullable_to_non_nullable
                      as String,
            familyId: null == familyId
                ? _value.familyId
                : familyId // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            category: null == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as GroceryItemCategory,
            qty: null == qty
                ? _value.qty
                : qty // ignore: cast_nullable_to_non_nullable
                      as int,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            unit: freezed == unit
                ? _value.unit
                : unit // ignore: cast_nullable_to_non_nullable
                      as String?,
            checked: null == checked
                ? _value.checked
                : checked // ignore: cast_nullable_to_non_nullable
                      as bool,
            checkedAt: freezed == checkedAt
                ? _value.checkedAt
                : checkedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
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
abstract class _$$GroceryTripItemModelImplCopyWith<$Res>
    implements $GroceryTripItemModelCopyWith<$Res> {
  factory _$$GroceryTripItemModelImplCopyWith(
    _$GroceryTripItemModelImpl value,
    $Res Function(_$GroceryTripItemModelImpl) then,
  ) = __$$GroceryTripItemModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String tripId,
    String familyId,
    String name,
    GroceryItemCategory category,
    int qty,
    String? notes,
    String? unit,
    bool checked,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$GroceryTripItemModelImplCopyWithImpl<$Res>
    extends _$GroceryTripItemModelCopyWithImpl<$Res, _$GroceryTripItemModelImpl>
    implements _$$GroceryTripItemModelImplCopyWith<$Res> {
  __$$GroceryTripItemModelImplCopyWithImpl(
    _$GroceryTripItemModelImpl _value,
    $Res Function(_$GroceryTripItemModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GroceryTripItemModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? tripId = null,
    Object? familyId = null,
    Object? name = null,
    Object? category = null,
    Object? qty = null,
    Object? notes = freezed,
    Object? unit = freezed,
    Object? checked = null,
    Object? checkedAt = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$GroceryTripItemModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        tripId: null == tripId
            ? _value.tripId
            : tripId // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        category: null == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as GroceryItemCategory,
        qty: null == qty
            ? _value.qty
            : qty // ignore: cast_nullable_to_non_nullable
                  as int,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        unit: freezed == unit
            ? _value.unit
            : unit // ignore: cast_nullable_to_non_nullable
                  as String?,
        checked: null == checked
            ? _value.checked
            : checked // ignore: cast_nullable_to_non_nullable
                  as bool,
        checkedAt: freezed == checkedAt
            ? _value.checkedAt
            : checkedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
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
class _$GroceryTripItemModelImpl extends _GroceryTripItemModel {
  const _$GroceryTripItemModelImpl({
    required this.id,
    required this.tripId,
    required this.familyId,
    required this.name,
    required this.category,
    this.qty = 1,
    this.notes,
    this.unit,
    this.checked = false,
    this.checkedAt,
    this.createdAt,
    this.updatedAt,
  }) : super._();

  factory _$GroceryTripItemModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryTripItemModelImplFromJson(json);

  @override
  final String id;
  @override
  final String tripId;
  @override
  final String familyId;
  @override
  final String name;
  @override
  final GroceryItemCategory category;
  @override
  @JsonKey()
  final int qty;
  @override
  final String? notes;
  @override
  final String? unit;
  @override
  @JsonKey()
  final bool checked;
  @override
  final DateTime? checkedAt;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'GroceryTripItemModel(id: $id, tripId: $tripId, familyId: $familyId, name: $name, category: $category, qty: $qty, notes: $notes, unit: $unit, checked: $checked, checkedAt: $checkedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryTripItemModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.tripId, tripId) || other.tripId == tripId) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.qty, qty) || other.qty == qty) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.checked, checked) || other.checked == checked) &&
            (identical(other.checkedAt, checkedAt) ||
                other.checkedAt == checkedAt) &&
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
    tripId,
    familyId,
    name,
    category,
    qty,
    notes,
    unit,
    checked,
    checkedAt,
    createdAt,
    updatedAt,
  );

  /// Create a copy of GroceryTripItemModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryTripItemModelImplCopyWith<_$GroceryTripItemModelImpl>
  get copyWith =>
      __$$GroceryTripItemModelImplCopyWithImpl<_$GroceryTripItemModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryTripItemModelImplToJson(this);
  }
}

abstract class _GroceryTripItemModel extends GroceryTripItemModel {
  const factory _GroceryTripItemModel({
    required final String id,
    required final String tripId,
    required final String familyId,
    required final String name,
    required final GroceryItemCategory category,
    final int qty,
    final String? notes,
    final String? unit,
    final bool checked,
    final DateTime? checkedAt,
    final DateTime? createdAt,
    final DateTime? updatedAt,
  }) = _$GroceryTripItemModelImpl;
  const _GroceryTripItemModel._() : super._();

  factory _GroceryTripItemModel.fromJson(Map<String, dynamic> json) =
      _$GroceryTripItemModelImpl.fromJson;

  @override
  String get id;
  @override
  String get tripId;
  @override
  String get familyId;
  @override
  String get name;
  @override
  GroceryItemCategory get category;
  @override
  int get qty;
  @override
  String? get notes;
  @override
  String? get unit;
  @override
  bool get checked;
  @override
  DateTime? get checkedAt;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of GroceryTripItemModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GroceryTripItemModelImplCopyWith<_$GroceryTripItemModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}
