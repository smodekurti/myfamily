// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'announcement_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AnnouncementModel _$AnnouncementModelFromJson(Map<String, dynamic> json) {
  return _AnnouncementModel.fromJson(json);
}

/// @nodoc
mixin _$AnnouncementModel {
  String get id => throw _privateConstructorUsedError;
  String get familyId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  String get createdBy => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  List<String> get readBy => throw _privateConstructorUsedError;

  /// Serializes this AnnouncementModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnnouncementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnnouncementModelCopyWith<AnnouncementModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnnouncementModelCopyWith<$Res> {
  factory $AnnouncementModelCopyWith(
    AnnouncementModel value,
    $Res Function(AnnouncementModel) then,
  ) = _$AnnouncementModelCopyWithImpl<$Res, AnnouncementModel>;
  @useResult
  $Res call({
    String id,
    String familyId,
    String title,
    String message,
    String createdBy,
    DateTime createdAt,
    DateTime? updatedAt,
    List<String> readBy,
  });
}

/// @nodoc
class _$AnnouncementModelCopyWithImpl<$Res, $Val extends AnnouncementModel>
    implements $AnnouncementModelCopyWith<$Res> {
  _$AnnouncementModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnnouncementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? title = null,
    Object? message = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? readBy = null,
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
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            readBy: null == readBy
                ? _value.readBy
                : readBy // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnnouncementModelImplCopyWith<$Res>
    implements $AnnouncementModelCopyWith<$Res> {
  factory _$$AnnouncementModelImplCopyWith(
    _$AnnouncementModelImpl value,
    $Res Function(_$AnnouncementModelImpl) then,
  ) = __$$AnnouncementModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String familyId,
    String title,
    String message,
    String createdBy,
    DateTime createdAt,
    DateTime? updatedAt,
    List<String> readBy,
  });
}

/// @nodoc
class __$$AnnouncementModelImplCopyWithImpl<$Res>
    extends _$AnnouncementModelCopyWithImpl<$Res, _$AnnouncementModelImpl>
    implements _$$AnnouncementModelImplCopyWith<$Res> {
  __$$AnnouncementModelImplCopyWithImpl(
    _$AnnouncementModelImpl _value,
    $Res Function(_$AnnouncementModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnnouncementModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? familyId = null,
    Object? title = null,
    Object? message = null,
    Object? createdBy = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? readBy = null,
  }) {
    return _then(
      _$AnnouncementModelImpl(
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
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        readBy: null == readBy
            ? _value._readBy
            : readBy // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnnouncementModelImpl implements _AnnouncementModel {
  const _$AnnouncementModelImpl({
    required this.id,
    required this.familyId,
    required this.title,
    required this.message,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    final List<String> readBy = const [],
  }) : _readBy = readBy;

  factory _$AnnouncementModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnnouncementModelImplFromJson(json);

  @override
  final String id;
  @override
  final String familyId;
  @override
  final String title;
  @override
  final String message;
  @override
  final String createdBy;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  final List<String> _readBy;
  @override
  @JsonKey()
  List<String> get readBy {
    if (_readBy is EqualUnmodifiableListView) return _readBy;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readBy);
  }

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, familyId: $familyId, title: $title, message: $message, createdBy: $createdBy, createdAt: $createdAt, updatedAt: $updatedAt, readBy: $readBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnnouncementModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.familyId, familyId) ||
                other.familyId == familyId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            const DeepCollectionEquality().equals(other._readBy, _readBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    familyId,
    title,
    message,
    createdBy,
    createdAt,
    updatedAt,
    const DeepCollectionEquality().hash(_readBy),
  );

  /// Create a copy of AnnouncementModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnnouncementModelImplCopyWith<_$AnnouncementModelImpl> get copyWith =>
      __$$AnnouncementModelImplCopyWithImpl<_$AnnouncementModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AnnouncementModelImplToJson(this);
  }
}

abstract class _AnnouncementModel implements AnnouncementModel {
  const factory _AnnouncementModel({
    required final String id,
    required final String familyId,
    required final String title,
    required final String message,
    required final String createdBy,
    required final DateTime createdAt,
    final DateTime? updatedAt,
    final List<String> readBy,
  }) = _$AnnouncementModelImpl;

  factory _AnnouncementModel.fromJson(Map<String, dynamic> json) =
      _$AnnouncementModelImpl.fromJson;

  @override
  String get id;
  @override
  String get familyId;
  @override
  String get title;
  @override
  String get message;
  @override
  String get createdBy;
  @override
  DateTime get createdAt;
  @override
  DateTime? get updatedAt;
  @override
  List<String> get readBy;

  /// Create a copy of AnnouncementModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnnouncementModelImplCopyWith<_$AnnouncementModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
