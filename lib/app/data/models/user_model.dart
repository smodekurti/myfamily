import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    required String uid,
    required String displayName,
    required String email,
    String? photoURL,
    @Default([]) List<String> families,
    @Default(0) int totalPoints,
    @Default('system') String themePreference,
    @Default(true) bool notificationsEnabled,
    int? age,
    DateTime? birthdate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

/// Extension for Supabase database conversion
extension UserModelSupabase on UserModel {
  /// Convert from Supabase format
  static UserModel fromSupabase(Map<String, dynamic> json) => UserModel(
        uid: json['id'] as String? ?? json['uid'] as String,
        displayName: json['display_name'] as String? ?? json['displayName'] as String? ?? 'User',
        email: json['email'] as String,
        photoURL: json['avatar_url'] as String? ?? json['photoURL'] as String?,
        families: (json['families'] as List<dynamic>?)?.cast<String>() ?? [],
        totalPoints: json['total_points'] as int? ?? json['totalPoints'] as int? ?? 0,
        themePreference: json['theme_preference'] as String? ?? json['themePreference'] as String? ?? 'system',
        notificationsEnabled: json['notifications_enabled'] as bool? ?? json['notificationsEnabled'] as bool? ?? true,
        age: json['age'] as int?,
        birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate'] as String) : null,
        createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
        updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
        deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : json['deletedAt'] != null ? DateTime.parse(json['deletedAt'] as String) : null,
      );

  /// Convert to Supabase format
  Map<String, dynamic> toSupabase() => {
        'id': uid,
        'display_name': displayName,
        'email': email,
        'avatar_url': photoURL,
        'families': families,
        'total_points': totalPoints,
        'theme_preference': themePreference,
        'notifications_enabled': notificationsEnabled,
        'age': age,
        'birthdate': birthdate?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'deleted_at': deletedAt?.toIso8601String(),
      };
}
