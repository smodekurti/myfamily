// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'family_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FamilyModel _$FamilyModelFromJson(Map<String, dynamic> json) {
  return _FamilyModel.fromJson(json);
}

/// @nodoc
mixin _$FamilyModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  List<String> get members => throw _privateConstructorUsedError;
  @JsonKey(name: 'invite_code')
  String? get inviteCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'child_invite_code')
  String? get childInviteCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'invite_link')
  String? get inviteLink => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  @JsonKey(name: 'theme_preference')
  String get themePreference => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_points')
  int get totalPoints => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyModelCopyWith<FamilyModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyModelCopyWith<$Res> {
  factory $FamilyModelCopyWith(
    FamilyModel value,
    $Res Function(FamilyModel) then,
  ) = _$FamilyModelCopyWithImpl<$Res, FamilyModel>;
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'created_by') String createdBy,
    List<String> members,
    @JsonKey(name: 'invite_code') String? inviteCode,
    @JsonKey(name: 'child_invite_code') String? childInviteCode,
    @JsonKey(name: 'invite_link') String? inviteLink,
    String? address,
    @JsonKey(name: 'theme_preference') String themePreference,
    @JsonKey(name: 'total_points') int totalPoints,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$FamilyModelCopyWithImpl<$Res, $Val extends FamilyModel>
    implements $FamilyModelCopyWith<$Res> {
  _$FamilyModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdBy = null,
    Object? members = null,
    Object? inviteCode = freezed,
    Object? childInviteCode = freezed,
    Object? inviteLink = freezed,
    Object? address = freezed,
    Object? themePreference = null,
    Object? totalPoints = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            members: null == members
                ? _value.members
                : members // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            inviteCode: freezed == inviteCode
                ? _value.inviteCode
                : inviteCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            childInviteCode: freezed == childInviteCode
                ? _value.childInviteCode
                : childInviteCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            inviteLink: freezed == inviteLink
                ? _value.inviteLink
                : inviteLink // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            themePreference: null == themePreference
                ? _value.themePreference
                : themePreference // ignore: cast_nullable_to_non_nullable
                      as String,
            totalPoints: null == totalPoints
                ? _value.totalPoints
                : totalPoints // ignore: cast_nullable_to_non_nullable
                      as int,
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
abstract class _$$FamilyModelImplCopyWith<$Res>
    implements $FamilyModelCopyWith<$Res> {
  factory _$$FamilyModelImplCopyWith(
    _$FamilyModelImpl value,
    $Res Function(_$FamilyModelImpl) then,
  ) = __$$FamilyModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    @JsonKey(name: 'created_by') String createdBy,
    List<String> members,
    @JsonKey(name: 'invite_code') String? inviteCode,
    @JsonKey(name: 'child_invite_code') String? childInviteCode,
    @JsonKey(name: 'invite_link') String? inviteLink,
    String? address,
    @JsonKey(name: 'theme_preference') String themePreference,
    @JsonKey(name: 'total_points') int totalPoints,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$FamilyModelImplCopyWithImpl<$Res>
    extends _$FamilyModelCopyWithImpl<$Res, _$FamilyModelImpl>
    implements _$$FamilyModelImplCopyWith<$Res> {
  __$$FamilyModelImplCopyWithImpl(
    _$FamilyModelImpl _value,
    $Res Function(_$FamilyModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? createdBy = null,
    Object? members = null,
    Object? inviteCode = freezed,
    Object? childInviteCode = freezed,
    Object? inviteLink = freezed,
    Object? address = freezed,
    Object? themePreference = null,
    Object? totalPoints = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$FamilyModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        members: null == members
            ? _value._members
            : members // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        inviteCode: freezed == inviteCode
            ? _value.inviteCode
            : inviteCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        childInviteCode: freezed == childInviteCode
            ? _value.childInviteCode
            : childInviteCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        inviteLink: freezed == inviteLink
            ? _value.inviteLink
            : inviteLink // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        themePreference: null == themePreference
            ? _value.themePreference
            : themePreference // ignore: cast_nullable_to_non_nullable
                  as String,
        totalPoints: null == totalPoints
            ? _value.totalPoints
            : totalPoints // ignore: cast_nullable_to_non_nullable
                  as int,
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
class _$FamilyModelImpl implements _FamilyModel {
  const _$FamilyModelImpl({
    required this.id,
    required this.name,
    @JsonKey(name: 'created_by') required this.createdBy,
    final List<String> members = const [],
    @JsonKey(name: 'invite_code') this.inviteCode,
    @JsonKey(name: 'child_invite_code') this.childInviteCode,
    @JsonKey(name: 'invite_link') this.inviteLink,
    this.address,
    @JsonKey(name: 'theme_preference') this.themePreference = 'system',
    @JsonKey(name: 'total_points') this.totalPoints = 0,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  }) : _members = members;

  factory _$FamilyModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  final List<String> _members;
  @override
  @JsonKey()
  List<String> get members {
    if (_members is EqualUnmodifiableListView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_members);
  }

  @override
  @JsonKey(name: 'invite_code')
  final String? inviteCode;
  @override
  @JsonKey(name: 'child_invite_code')
  final String? childInviteCode;
  @override
  @JsonKey(name: 'invite_link')
  final String? inviteLink;
  @override
  final String? address;
  @override
  @JsonKey(name: 'theme_preference')
  final String themePreference;
  @override
  @JsonKey(name: 'total_points')
  final int totalPoints;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FamilyModel(id: $id, name: $name, createdBy: $createdBy, members: $members, inviteCode: $inviteCode, childInviteCode: $childInviteCode, inviteLink: $inviteLink, address: $address, themePreference: $themePreference, totalPoints: $totalPoints, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            const DeepCollectionEquality().equals(other._members, _members) &&
            (identical(other.inviteCode, inviteCode) ||
                other.inviteCode == inviteCode) &&
            (identical(other.childInviteCode, childInviteCode) ||
                other.childInviteCode == childInviteCode) &&
            (identical(other.inviteLink, inviteLink) ||
                other.inviteLink == inviteLink) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.themePreference, themePreference) ||
                other.themePreference == themePreference) &&
            (identical(other.totalPoints, totalPoints) ||
                other.totalPoints == totalPoints) &&
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
    name,
    createdBy,
    const DeepCollectionEquality().hash(_members),
    inviteCode,
    childInviteCode,
    inviteLink,
    address,
    themePreference,
    totalPoints,
    createdAt,
    updatedAt,
  );

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyModelImplCopyWith<_$FamilyModelImpl> get copyWith =>
      __$$FamilyModelImplCopyWithImpl<_$FamilyModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyModelImplToJson(this);
  }
}

abstract class _FamilyModel implements FamilyModel {
  const factory _FamilyModel({
    required final String id,
    required final String name,
    @JsonKey(name: 'created_by') required final String createdBy,
    final List<String> members,
    @JsonKey(name: 'invite_code') final String? inviteCode,
    @JsonKey(name: 'child_invite_code') final String? childInviteCode,
    @JsonKey(name: 'invite_link') final String? inviteLink,
    final String? address,
    @JsonKey(name: 'theme_preference') final String themePreference,
    @JsonKey(name: 'total_points') final int totalPoints,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$FamilyModelImpl;

  factory _FamilyModel.fromJson(Map<String, dynamic> json) =
      _$FamilyModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  List<String> get members;
  @override
  @JsonKey(name: 'invite_code')
  String? get inviteCode;
  @override
  @JsonKey(name: 'child_invite_code')
  String? get childInviteCode;
  @override
  @JsonKey(name: 'invite_link')
  String? get inviteLink;
  @override
  String? get address;
  @override
  @JsonKey(name: 'theme_preference')
  String get themePreference;
  @override
  @JsonKey(name: 'total_points')
  int get totalPoints;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of FamilyModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyModelImplCopyWith<_$FamilyModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FamilyMemberModel _$FamilyMemberModelFromJson(Map<String, dynamic> json) {
  return _FamilyMemberModel.fromJson(json);
}

/// @nodoc
mixin _$FamilyMemberModel {
  String get uid => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get photoURL => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  int get points => throw _privateConstructorUsedError;
  List<String> get notificationTokens => throw _privateConstructorUsedError;
  DateTime? get joinedAt => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FamilyMemberModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FamilyMemberModelCopyWith<FamilyMemberModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FamilyMemberModelCopyWith<$Res> {
  factory $FamilyMemberModelCopyWith(
    FamilyMemberModel value,
    $Res Function(FamilyMemberModel) then,
  ) = _$FamilyMemberModelCopyWithImpl<$Res, FamilyMemberModel>;
  @useResult
  $Res call({
    String uid,
    String displayName,
    String? photoURL,
    String role,
    int points,
    List<String> notificationTokens,
    DateTime? joinedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$FamilyMemberModelCopyWithImpl<$Res, $Val extends FamilyMemberModel>
    implements $FamilyMemberModelCopyWith<$Res> {
  _$FamilyMemberModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? role = null,
    Object? points = null,
    Object? notificationTokens = null,
    Object? joinedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            uid: null == uid
                ? _value.uid
                : uid // ignore: cast_nullable_to_non_nullable
                      as String,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            photoURL: freezed == photoURL
                ? _value.photoURL
                : photoURL // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            points: null == points
                ? _value.points
                : points // ignore: cast_nullable_to_non_nullable
                      as int,
            notificationTokens: null == notificationTokens
                ? _value.notificationTokens
                : notificationTokens // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            joinedAt: freezed == joinedAt
                ? _value.joinedAt
                : joinedAt // ignore: cast_nullable_to_non_nullable
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
abstract class _$$FamilyMemberModelImplCopyWith<$Res>
    implements $FamilyMemberModelCopyWith<$Res> {
  factory _$$FamilyMemberModelImplCopyWith(
    _$FamilyMemberModelImpl value,
    $Res Function(_$FamilyMemberModelImpl) then,
  ) = __$$FamilyMemberModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String uid,
    String displayName,
    String? photoURL,
    String role,
    int points,
    List<String> notificationTokens,
    DateTime? joinedAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$FamilyMemberModelImplCopyWithImpl<$Res>
    extends _$FamilyMemberModelCopyWithImpl<$Res, _$FamilyMemberModelImpl>
    implements _$$FamilyMemberModelImplCopyWith<$Res> {
  __$$FamilyMemberModelImplCopyWithImpl(
    _$FamilyMemberModelImpl _value,
    $Res Function(_$FamilyMemberModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? displayName = null,
    Object? photoURL = freezed,
    Object? role = null,
    Object? points = null,
    Object? notificationTokens = null,
    Object? joinedAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$FamilyMemberModelImpl(
        uid: null == uid
            ? _value.uid
            : uid // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        photoURL: freezed == photoURL
            ? _value.photoURL
            : photoURL // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        points: null == points
            ? _value.points
            : points // ignore: cast_nullable_to_non_nullable
                  as int,
        notificationTokens: null == notificationTokens
            ? _value._notificationTokens
            : notificationTokens // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        joinedAt: freezed == joinedAt
            ? _value.joinedAt
            : joinedAt // ignore: cast_nullable_to_non_nullable
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
class _$FamilyMemberModelImpl implements _FamilyMemberModel {
  const _$FamilyMemberModelImpl({
    required this.uid,
    required this.displayName,
    this.photoURL,
    required this.role,
    this.points = 0,
    final List<String> notificationTokens = const [],
    this.joinedAt,
    this.updatedAt,
  }) : _notificationTokens = notificationTokens;

  factory _$FamilyMemberModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$FamilyMemberModelImplFromJson(json);

  @override
  final String uid;
  @override
  final String displayName;
  @override
  final String? photoURL;
  @override
  final String role;
  @override
  @JsonKey()
  final int points;
  final List<String> _notificationTokens;
  @override
  @JsonKey()
  List<String> get notificationTokens {
    if (_notificationTokens is EqualUnmodifiableListView)
      return _notificationTokens;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notificationTokens);
  }

  @override
  final DateTime? joinedAt;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FamilyMemberModel(uid: $uid, displayName: $displayName, photoURL: $photoURL, role: $role, points: $points, notificationTokens: $notificationTokens, joinedAt: $joinedAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FamilyMemberModelImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.photoURL, photoURL) ||
                other.photoURL == photoURL) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.points, points) || other.points == points) &&
            const DeepCollectionEquality().equals(
              other._notificationTokens,
              _notificationTokens,
            ) &&
            (identical(other.joinedAt, joinedAt) ||
                other.joinedAt == joinedAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    uid,
    displayName,
    photoURL,
    role,
    points,
    const DeepCollectionEquality().hash(_notificationTokens),
    joinedAt,
    updatedAt,
  );

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FamilyMemberModelImplCopyWith<_$FamilyMemberModelImpl> get copyWith =>
      __$$FamilyMemberModelImplCopyWithImpl<_$FamilyMemberModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FamilyMemberModelImplToJson(this);
  }
}

abstract class _FamilyMemberModel implements FamilyMemberModel {
  const factory _FamilyMemberModel({
    required final String uid,
    required final String displayName,
    final String? photoURL,
    required final String role,
    final int points,
    final List<String> notificationTokens,
    final DateTime? joinedAt,
    final DateTime? updatedAt,
  }) = _$FamilyMemberModelImpl;

  factory _FamilyMemberModel.fromJson(Map<String, dynamic> json) =
      _$FamilyMemberModelImpl.fromJson;

  @override
  String get uid;
  @override
  String get displayName;
  @override
  String? get photoURL;
  @override
  String get role;
  @override
  int get points;
  @override
  List<String> get notificationTokens;
  @override
  DateTime? get joinedAt;
  @override
  DateTime? get updatedAt;

  /// Create a copy of FamilyMemberModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FamilyMemberModelImplCopyWith<_$FamilyMemberModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
