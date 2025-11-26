import 'package:freezed_annotation/freezed_annotation.dart';

part 'announcement_model.freezed.dart';
part 'announcement_model.g.dart';

@freezed
class AnnouncementModel with _$AnnouncementModel {
  const factory AnnouncementModel({
    required String id,
    required String familyId,
    required String title,
    required String message,
    required String createdBy,
    required DateTime createdAt,
    DateTime? updatedAt,
    @Default([]) List<String> readBy,
  }) = _AnnouncementModel;

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) => _$AnnouncementModelFromJson(json);
}

class AnnouncementModelHelpers {
  static AnnouncementModel fromSupabase(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      readBy: (json['read_by'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static Map<String, dynamic> toSupabase(AnnouncementModel announcement) {
    return {
      'id': announcement.id,
      'family_id': announcement.familyId,
      'title': announcement.title,
      'message': announcement.message,
      'created_by': announcement.createdBy,
      'created_at': announcement.createdAt.toIso8601String(),
      'updated_at': announcement.updatedAt?.toIso8601String(),
      'read_by': announcement.readBy,
    };
  }
}

