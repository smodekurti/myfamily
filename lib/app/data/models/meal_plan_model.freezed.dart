// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_plan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MealPlanModel _$MealPlanModelFromJson(Map<String, dynamic> json) {
  return _MealPlanModel.fromJson(json);
}

/// @nodoc
mixin _$MealPlanModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  DateTime get startDate => throw _privateConstructorUsedError;
  DateTime get endDate => throw _privateConstructorUsedError;
  DateTime? get createdAt =>
      throw _privateConstructorUsedError; // Optional list of entries, populated when fetching full plan
  List<MealPlanEntryModel>? get entries => throw _privateConstructorUsedError;

  /// Serializes this MealPlanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MealPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealPlanModelCopyWith<MealPlanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanModelCopyWith<$Res> {
  factory $MealPlanModelCopyWith(
    MealPlanModel value,
    $Res Function(MealPlanModel) then,
  ) = _$MealPlanModelCopyWithImpl<$Res, MealPlanModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    DateTime startDate,
    DateTime endDate,
    DateTime? createdAt,
    List<MealPlanEntryModel>? entries,
  });
}

/// @nodoc
class _$MealPlanModelCopyWithImpl<$Res, $Val extends MealPlanModel>
    implements $MealPlanModelCopyWith<$Res> {
  _$MealPlanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? createdAt = freezed,
    Object? entries = freezed,
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
            startDate: null == startDate
                ? _value.startDate
                : startDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endDate: null == endDate
                ? _value.endDate
                : endDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            entries: freezed == entries
                ? _value.entries
                : entries // ignore: cast_nullable_to_non_nullable
                      as List<MealPlanEntryModel>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealPlanModelImplCopyWith<$Res>
    implements $MealPlanModelCopyWith<$Res> {
  factory _$$MealPlanModelImplCopyWith(
    _$MealPlanModelImpl value,
    $Res Function(_$MealPlanModelImpl) then,
  ) = __$$MealPlanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    DateTime startDate,
    DateTime endDate,
    DateTime? createdAt,
    List<MealPlanEntryModel>? entries,
  });
}

/// @nodoc
class __$$MealPlanModelImplCopyWithImpl<$Res>
    extends _$MealPlanModelCopyWithImpl<$Res, _$MealPlanModelImpl>
    implements _$$MealPlanModelImplCopyWith<$Res> {
  __$$MealPlanModelImplCopyWithImpl(
    _$MealPlanModelImpl _value,
    $Res Function(_$MealPlanModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MealPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? startDate = null,
    Object? endDate = null,
    Object? createdAt = freezed,
    Object? entries = freezed,
  }) {
    return _then(
      _$MealPlanModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        startDate: null == startDate
            ? _value.startDate
            : startDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endDate: null == endDate
            ? _value.endDate
            : endDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        entries: freezed == entries
            ? _value._entries
            : entries // ignore: cast_nullable_to_non_nullable
                  as List<MealPlanEntryModel>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealPlanModelImpl implements _MealPlanModel {
  const _$MealPlanModelImpl({
    required this.id,
    required this.familyId,
    required this.startDate,
    required this.endDate,
    this.createdAt,
    final List<MealPlanEntryModel>? entries,
  }) : _entries = entries;

  factory _$MealPlanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealPlanModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final DateTime startDate;
  @override
  final DateTime endDate;
  @override
  final DateTime? createdAt;
  // Optional list of entries, populated when fetching full plan
  final List<MealPlanEntryModel>? _entries;
  // Optional list of entries, populated when fetching full plan
  @override
  List<MealPlanEntryModel>? get entries {
    final value = _entries;
    if (value == null) return null;
    if (_entries is EqualUnmodifiableListView) return _entries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'MealPlanModel(id: $id, familyId: $familyId, startDate: $startDate, endDate: $endDate, createdAt: $createdAt, entries: $entries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            (identical(other.endDate, endDate) || other.endDate == endDate) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._entries, _entries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    startDate,
    endDate,
    createdAt,
    const DeepCollectionEquality().hash(_entries),
  );

  /// Create a copy of MealPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanModelImplCopyWith<_$MealPlanModelImpl> get copyWith =>
      __$$MealPlanModelImplCopyWithImpl<_$MealPlanModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealPlanModelImplToJson(this);
  }
}

abstract class _MealPlanModel implements MealPlanModel {
  const factory _MealPlanModel({
    required final String id,
    required final String familyId,
    required final DateTime startDate,
    required final DateTime endDate,
    final DateTime? createdAt,
    final List<MealPlanEntryModel>? entries,
  }) = _$MealPlanModelImpl;

  factory _MealPlanModel.fromJson(Map<String, dynamic> json) =
      _$MealPlanModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  DateTime get startDate;
  @override
  DateTime get endDate;
  @override
  DateTime? get createdAt; // Optional list of entries, populated when fetching full plan
  @override
  List<MealPlanEntryModel>? get entries;

  /// Create a copy of MealPlanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealPlanModelImplCopyWith<_$MealPlanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealPlanEntryModel _$MealPlanEntryModelFromJson(Map<String, dynamic> json) {
  return _MealPlanEntryModel.fromJson(json);
}

/// @nodoc
mixin _$MealPlanEntryModel {
  String get id => throw _privateConstructorUsedError;
  String get planId => throw _privateConstructorUsedError;
  String? get recipeId => throw _privateConstructorUsedError;
  DateTime get mealDate => throw _privateConstructorUsedError;
  String get mealType =>
      throw _privateConstructorUsedError; // 'breakfast', 'lunch', 'dinner', 'snack'
  String? get customNote => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime? get createdAt =>
      throw _privateConstructorUsedError; // Optional joined fields
  String? get recipeTitle => throw _privateConstructorUsedError;
  String? get recipeImageUrl => throw _privateConstructorUsedError;

  /// Serializes this MealPlanEntryModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MealPlanEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealPlanEntryModelCopyWith<MealPlanEntryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanEntryModelCopyWith<$Res> {
  factory $MealPlanEntryModelCopyWith(
    MealPlanEntryModel value,
    $Res Function(MealPlanEntryModel) then,
  ) = _$MealPlanEntryModelCopyWithImpl<$Res, MealPlanEntryModel>;
  @useResult
  $Res call({
    String id,
    String planId,
    String? recipeId,
    DateTime mealDate,
    String mealType,
    String? customNote,
    bool isCompleted,
    DateTime? createdAt,
    String? recipeTitle,
    String? recipeImageUrl,
  });
}

/// @nodoc
class _$MealPlanEntryModelCopyWithImpl<$Res, $Val extends MealPlanEntryModel>
    implements $MealPlanEntryModelCopyWith<$Res> {
  _$MealPlanEntryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealPlanEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? recipeId = freezed,
    Object? mealDate = null,
    Object? mealType = null,
    Object? customNote = freezed,
    Object? isCompleted = null,
    Object? createdAt = freezed,
    Object? recipeTitle = freezed,
    Object? recipeImageUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            planId: null == planId
                ? _value.planId
                : planId // ignore: cast_nullable_to_non_nullable
                      as String,
            recipeId: freezed == recipeId
                ? _value.recipeId
                : recipeId // ignore: cast_nullable_to_non_nullable
                      as String?,
            mealDate: null == mealDate
                ? _value.mealDate
                : mealDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            mealType: null == mealType
                ? _value.mealType
                : mealType // ignore: cast_nullable_to_non_nullable
                      as String,
            customNote: freezed == customNote
                ? _value.customNote
                : customNote // ignore: cast_nullable_to_non_nullable
                      as String?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            recipeTitle: freezed == recipeTitle
                ? _value.recipeTitle
                : recipeTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            recipeImageUrl: freezed == recipeImageUrl
                ? _value.recipeImageUrl
                : recipeImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealPlanEntryModelImplCopyWith<$Res>
    implements $MealPlanEntryModelCopyWith<$Res> {
  factory _$$MealPlanEntryModelImplCopyWith(
    _$MealPlanEntryModelImpl value,
    $Res Function(_$MealPlanEntryModelImpl) then,
  ) = __$$MealPlanEntryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String planId,
    String? recipeId,
    DateTime mealDate,
    String mealType,
    String? customNote,
    bool isCompleted,
    DateTime? createdAt,
    String? recipeTitle,
    String? recipeImageUrl,
  });
}

/// @nodoc
class __$$MealPlanEntryModelImplCopyWithImpl<$Res>
    extends _$MealPlanEntryModelCopyWithImpl<$Res, _$MealPlanEntryModelImpl>
    implements _$$MealPlanEntryModelImplCopyWith<$Res> {
  __$$MealPlanEntryModelImplCopyWithImpl(
    _$MealPlanEntryModelImpl _value,
    $Res Function(_$MealPlanEntryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MealPlanEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? planId = null,
    Object? recipeId = freezed,
    Object? mealDate = null,
    Object? mealType = null,
    Object? customNote = freezed,
    Object? isCompleted = null,
    Object? createdAt = freezed,
    Object? recipeTitle = freezed,
    Object? recipeImageUrl = freezed,
  }) {
    return _then(
      _$MealPlanEntryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        planId: null == planId
            ? _value.planId
            : planId // ignore: cast_nullable_to_non_nullable
                  as String,
        recipeId: freezed == recipeId
            ? _value.recipeId
            : recipeId // ignore: cast_nullable_to_non_nullable
                  as String?,
        mealDate: null == mealDate
            ? _value.mealDate
            : mealDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        mealType: null == mealType
            ? _value.mealType
            : mealType // ignore: cast_nullable_to_non_nullable
                  as String,
        customNote: freezed == customNote
            ? _value.customNote
            : customNote // ignore: cast_nullable_to_non_nullable
                  as String?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        recipeTitle: freezed == recipeTitle
            ? _value.recipeTitle
            : recipeTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        recipeImageUrl: freezed == recipeImageUrl
            ? _value.recipeImageUrl
            : recipeImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealPlanEntryModelImpl implements _MealPlanEntryModel {
  const _$MealPlanEntryModelImpl({
    required this.id,
    required this.planId,
    this.recipeId,
    required this.mealDate,
    required this.mealType,
    this.customNote,
    this.isCompleted = false,
    this.createdAt,
    this.recipeTitle,
    this.recipeImageUrl,
  });

  factory _$MealPlanEntryModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealPlanEntryModelImplFromJson(json);

  @override
  final String id;
  @override
  final String planId;
  @override
  final String? recipeId;
  @override
  final DateTime mealDate;
  @override
  final String mealType;
  // 'breakfast', 'lunch', 'dinner', 'snack'
  @override
  final String? customNote;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime? createdAt;
  // Optional joined fields
  @override
  final String? recipeTitle;
  @override
  final String? recipeImageUrl;

  @override
  String toString() {
    return 'MealPlanEntryModel(id: $id, planId: $planId, recipeId: $recipeId, mealDate: $mealDate, mealType: $mealType, customNote: $customNote, isCompleted: $isCompleted, createdAt: $createdAt, recipeTitle: $recipeTitle, recipeImageUrl: $recipeImageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanEntryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.planId, planId) || other.planId == planId) &&
            (identical(other.recipeId, recipeId) ||
                other.recipeId == recipeId) &&
            (identical(other.mealDate, mealDate) ||
                other.mealDate == mealDate) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            (identical(other.customNote, customNote) ||
                other.customNote == customNote) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.recipeTitle, recipeTitle) ||
                other.recipeTitle == recipeTitle) &&
            (identical(other.recipeImageUrl, recipeImageUrl) ||
                other.recipeImageUrl == recipeImageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    planId,
    recipeId,
    mealDate,
    mealType,
    customNote,
    isCompleted,
    createdAt,
    recipeTitle,
    recipeImageUrl,
  );

  /// Create a copy of MealPlanEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanEntryModelImplCopyWith<_$MealPlanEntryModelImpl> get copyWith =>
      __$$MealPlanEntryModelImplCopyWithImpl<_$MealPlanEntryModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MealPlanEntryModelImplToJson(this);
  }
}

abstract class _MealPlanEntryModel implements MealPlanEntryModel {
  const factory _MealPlanEntryModel({
    required final String id,
    required final String planId,
    final String? recipeId,
    required final DateTime mealDate,
    required final String mealType,
    final String? customNote,
    final bool isCompleted,
    final DateTime? createdAt,
    final String? recipeTitle,
    final String? recipeImageUrl,
  }) = _$MealPlanEntryModelImpl;

  factory _MealPlanEntryModel.fromJson(Map<String, dynamic> json) =
      _$MealPlanEntryModelImpl.fromJson;

  @override
  String get id;
  @override
  String get planId;
  @override
  String? get recipeId;
  @override
  DateTime get mealDate;
  @override
  String get mealType; // 'breakfast', 'lunch', 'dinner', 'snack'
  @override
  String? get customNote;
  @override
  bool get isCompleted;
  @override
  DateTime? get createdAt; // Optional joined fields
  @override
  String? get recipeTitle;
  @override
  String? get recipeImageUrl;

  /// Create a copy of MealPlanEntryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealPlanEntryModelImplCopyWith<_$MealPlanEntryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
