// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'meal_vote_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MealVoteSessionModel _$MealVoteSessionModelFromJson(Map<String, dynamic> json) {
  return _MealVoteSessionModel.fromJson(json);
}

/// @nodoc
mixin _$MealVoteSessionModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  DateTime get mealDate => throw _privateConstructorUsedError;
  String get mealType => throw _privateConstructorUsedError;
  List<MealVoteOption> get options => throw _privateConstructorUsedError;
  Map<String, int> get votes =>
      throw _privateConstructorUsedError; // userId -> optionIndex
  String get status =>
      throw _privateConstructorUsedError; // 'active', 'completed'
  int? get winnerOptionIndex => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this MealVoteSessionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MealVoteSessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealVoteSessionModelCopyWith<MealVoteSessionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealVoteSessionModelCopyWith<$Res> {
  factory $MealVoteSessionModelCopyWith(
    MealVoteSessionModel value,
    $Res Function(MealVoteSessionModel) then,
  ) = _$MealVoteSessionModelCopyWithImpl<$Res, MealVoteSessionModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    DateTime mealDate,
    String mealType,
    List<MealVoteOption> options,
    Map<String, int> votes,
    String status,
    int? winnerOptionIndex,
    DateTime? createdAt,
  });
}

/// @nodoc
class _$MealVoteSessionModelCopyWithImpl<
  $Res,
  $Val extends MealVoteSessionModel
>
    implements $MealVoteSessionModelCopyWith<$Res> {
  _$MealVoteSessionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealVoteSessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? mealDate = null,
    Object? mealType = null,
    Object? options = null,
    Object? votes = null,
    Object? status = null,
    Object? winnerOptionIndex = freezed,
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
            mealDate: null == mealDate
                ? _value.mealDate
                : mealDate // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            mealType: null == mealType
                ? _value.mealType
                : mealType // ignore: cast_nullable_to_non_nullable
                      as String,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<MealVoteOption>,
            votes: null == votes
                ? _value.votes
                : votes // ignore: cast_nullable_to_non_nullable
                      as Map<String, int>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            winnerOptionIndex: freezed == winnerOptionIndex
                ? _value.winnerOptionIndex
                : winnerOptionIndex // ignore: cast_nullable_to_non_nullable
                      as int?,
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
abstract class _$$MealVoteSessionModelImplCopyWith<$Res>
    implements $MealVoteSessionModelCopyWith<$Res> {
  factory _$$MealVoteSessionModelImplCopyWith(
    _$MealVoteSessionModelImpl value,
    $Res Function(_$MealVoteSessionModelImpl) then,
  ) = __$$MealVoteSessionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    DateTime mealDate,
    String mealType,
    List<MealVoteOption> options,
    Map<String, int> votes,
    String status,
    int? winnerOptionIndex,
    DateTime? createdAt,
  });
}

/// @nodoc
class __$$MealVoteSessionModelImplCopyWithImpl<$Res>
    extends _$MealVoteSessionModelCopyWithImpl<$Res, _$MealVoteSessionModelImpl>
    implements _$$MealVoteSessionModelImplCopyWith<$Res> {
  __$$MealVoteSessionModelImplCopyWithImpl(
    _$MealVoteSessionModelImpl _value,
    $Res Function(_$MealVoteSessionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MealVoteSessionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? mealDate = null,
    Object? mealType = null,
    Object? options = null,
    Object? votes = null,
    Object? status = null,
    Object? winnerOptionIndex = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$MealVoteSessionModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        familyId: null == familyId
            ? _value.familyId
            : familyId // ignore: cast_nullable_to_non_nullable
                  as String,
        mealDate: null == mealDate
            ? _value.mealDate
            : mealDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        mealType: null == mealType
            ? _value.mealType
            : mealType // ignore: cast_nullable_to_non_nullable
                  as String,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<MealVoteOption>,
        votes: null == votes
            ? _value._votes
            : votes // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        winnerOptionIndex: freezed == winnerOptionIndex
            ? _value.winnerOptionIndex
            : winnerOptionIndex // ignore: cast_nullable_to_non_nullable
                  as int?,
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
class _$MealVoteSessionModelImpl implements _MealVoteSessionModel {
  const _$MealVoteSessionModelImpl({
    required this.id,
    required this.familyId,
    required this.mealDate,
    required this.mealType,
    required final List<MealVoteOption> options,
    final Map<String, int> votes = const {},
    this.status = 'active',
    this.winnerOptionIndex,
    this.createdAt,
  }) : _options = options,
       _votes = votes;

  factory _$MealVoteSessionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealVoteSessionModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final DateTime mealDate;
  @override
  final String mealType;
  final List<MealVoteOption> _options;
  @override
  List<MealVoteOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  final Map<String, int> _votes;
  @override
  @JsonKey()
  Map<String, int> get votes {
    if (_votes is EqualUnmodifiableMapView) return _votes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_votes);
  }

  // userId -> optionIndex
  @override
  @JsonKey()
  final String status;
  // 'active', 'completed'
  @override
  final int? winnerOptionIndex;
  @override
  final DateTime? createdAt;

  @override
  String toString() {
    return 'MealVoteSessionModel(id: $id, familyId: $familyId, mealDate: $mealDate, mealType: $mealType, options: $options, votes: $votes, status: $status, winnerOptionIndex: $winnerOptionIndex, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealVoteSessionModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.mealDate, mealDate) ||
                other.mealDate == mealDate) &&
            (identical(other.mealType, mealType) ||
                other.mealType == mealType) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            const DeepCollectionEquality().equals(other._votes, _votes) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.winnerOptionIndex, winnerOptionIndex) ||
                other.winnerOptionIndex == winnerOptionIndex) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    mealDate,
    mealType,
    const DeepCollectionEquality().hash(_options),
    const DeepCollectionEquality().hash(_votes),
    status,
    winnerOptionIndex,
    createdAt,
  );

  /// Create a copy of MealVoteSessionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealVoteSessionModelImplCopyWith<_$MealVoteSessionModelImpl>
  get copyWith =>
      __$$MealVoteSessionModelImplCopyWithImpl<_$MealVoteSessionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MealVoteSessionModelImplToJson(this);
  }
}

abstract class _MealVoteSessionModel implements MealVoteSessionModel {
  const factory _MealVoteSessionModel({
    required final String id,
    required final String familyId,
    required final DateTime mealDate,
    required final String mealType,
    required final List<MealVoteOption> options,
    final Map<String, int> votes,
    final String status,
    final int? winnerOptionIndex,
    final DateTime? createdAt,
  }) = _$MealVoteSessionModelImpl;

  factory _MealVoteSessionModel.fromJson(Map<String, dynamic> json) =
      _$MealVoteSessionModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  DateTime get mealDate;
  @override
  String get mealType;
  @override
  List<MealVoteOption> get options;
  @override
  Map<String, int> get votes; // userId -> optionIndex
  @override
  String get status; // 'active', 'completed'
  @override
  int? get winnerOptionIndex;
  @override
  DateTime? get createdAt;

  /// Create a copy of MealVoteSessionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealVoteSessionModelImplCopyWith<_$MealVoteSessionModelImpl>
  get copyWith => throw _privateConstructorUsedError;
}

MealVoteOption _$MealVoteOptionFromJson(Map<String, dynamic> json) {
  return _MealVoteOption.fromJson(json);
}

/// @nodoc
mixin _$MealVoteOption {
  String get title => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;

  /// Serializes this MealVoteOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MealVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MealVoteOptionCopyWith<MealVoteOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealVoteOptionCopyWith<$Res> {
  factory $MealVoteOptionCopyWith(
    MealVoteOption value,
    $Res Function(MealVoteOption) then,
  ) = _$MealVoteOptionCopyWithImpl<$Res, MealVoteOption>;
  @useResult
  $Res call({String title, String description});
}

/// @nodoc
class _$MealVoteOptionCopyWithImpl<$Res, $Val extends MealVoteOption>
    implements $MealVoteOptionCopyWith<$Res> {
  _$MealVoteOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MealVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = null, Object? description = null}) {
    return _then(
      _value.copyWith(
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            description: null == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MealVoteOptionImplCopyWith<$Res>
    implements $MealVoteOptionCopyWith<$Res> {
  factory _$$MealVoteOptionImplCopyWith(
    _$MealVoteOptionImpl value,
    $Res Function(_$MealVoteOptionImpl) then,
  ) = __$$MealVoteOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, String description});
}

/// @nodoc
class __$$MealVoteOptionImplCopyWithImpl<$Res>
    extends _$MealVoteOptionCopyWithImpl<$Res, _$MealVoteOptionImpl>
    implements _$$MealVoteOptionImplCopyWith<$Res> {
  __$$MealVoteOptionImplCopyWithImpl(
    _$MealVoteOptionImpl _value,
    $Res Function(_$MealVoteOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MealVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? title = null, Object? description = null}) {
    return _then(
      _$MealVoteOptionImpl(
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        description: null == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MealVoteOptionImpl implements _MealVoteOption {
  const _$MealVoteOptionImpl({required this.title, required this.description});

  factory _$MealVoteOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealVoteOptionImplFromJson(json);

  @override
  final String title;
  @override
  final String description;

  @override
  String toString() {
    return 'MealVoteOption(title: $title, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealVoteOptionImpl &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, title, description);

  /// Create a copy of MealVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MealVoteOptionImplCopyWith<_$MealVoteOptionImpl> get copyWith =>
      __$$MealVoteOptionImplCopyWithImpl<_$MealVoteOptionImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$MealVoteOptionImplToJson(this);
  }
}

abstract class _MealVoteOption implements MealVoteOption {
  const factory _MealVoteOption({
    required final String title,
    required final String description,
  }) = _$MealVoteOptionImpl;

  factory _MealVoteOption.fromJson(Map<String, dynamic> json) =
      _$MealVoteOptionImpl.fromJson;

  @override
  String get title;
  @override
  String get description;

  /// Create a copy of MealVoteOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MealVoteOptionImplCopyWith<_$MealVoteOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
