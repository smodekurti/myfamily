import 'package:freezed_annotation/freezed_annotation.dart';

part 'points_history_model.freezed.dart';
part 'points_history_model.g.dart';

@freezed
class PointsHistoryModel with _$PointsHistoryModel {
  const factory PointsHistoryModel({
    required String id,
    required String familyId,
    required String userId,
    required int points, // Can be positive (awarded) or negative (removed)
    required String reason, // e.g., 'task_completed', 'task_uncompleted', 'bonus', etc.
    String? taskId, // Reference to task if points are from task completion
    String? taskTitle, // Task title for display
    DateTime? createdAt,
  }) = _PointsHistoryModel;

  factory PointsHistoryModel.fromJson(Map<String, dynamic> json) => _$PointsHistoryModelFromJson(json);
}

// Helper functions for Supabase integration
class PointsHistoryModelHelpers {
  static PointsHistoryModel fromSupabase(Map<String, dynamic> json) => PointsHistoryModel(
    id: json['id'] as String,
    familyId: json['family_id'] as String,
    userId: json['user_id'] as String,
    points: json['points'] as int,
    reason: json['reason'] as String,
    taskId: json['task_id'] as String?,
    taskTitle: json['task_title'] as String?,
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
  );

  static Map<String, dynamic> toSupabase(PointsHistoryModel history) => {
    'id': history.id,
    'family_id': history.familyId,
    'user_id': history.userId,
    'points': history.points,
    'reason': history.reason,
    'task_id': history.taskId,
    'task_title': history.taskTitle,
    'created_at': history.createdAt?.toIso8601String(),
  };
}

