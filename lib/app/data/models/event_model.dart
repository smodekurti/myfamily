import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_model.freezed.dart';
part 'event_model.g.dart';

@freezed
class EventModel with _$EventModel {
  const factory EventModel({
    required String id,
    @JsonKey(name: 'family_id') required String familyId,
    required String title,
    String? description,
    @JsonKey(name: 'start_time') required DateTime startTime,
    @JsonKey(name: 'end_time') required DateTime endTime,
    String? location,
    @JsonKey(name: 'created_by') required String createdBy,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    String? color, // Optional color for event indicator
    @Default([]) List<String> participants, // List of user IDs
  }) = _EventModel;

  factory EventModel.fromJson(Map<String, dynamic> json) => _$EventModelFromJson(json);
}

// Helper class for Supabase JSON conversion
class EventModelHelpers {
  static EventModel fromSupabase(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      location: json['location'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      color: json['color'] as String?,
      participants: (json['participants'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  static Map<String, dynamic> toSupabase(EventModel event) {
    return {
      'id': event.id,
      'family_id': event.familyId,
      'title': event.title,
      'description': event.description,
      'start_time': event.startTime.toIso8601String(),
      'end_time': event.endTime.toIso8601String(),
      'location': event.location,
      'created_by': event.createdBy,
      'created_at': event.createdAt?.toIso8601String(),
      'updated_at': event.updatedAt?.toIso8601String(),
      'color': event.color,
      'participants': event.participants,
    };
  }
}

