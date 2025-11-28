import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/points_history_model.dart';

class PointsHistoryRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  /// Log a points transaction
  Future<void> logPointsTransaction({
    required String familyId,
    required String userId,
    required int points,
    required String reason,
    String? taskId,
    String? taskTitle,
  }) async {
    try {
      final now = DateTime.now();
      final historyData = {
        'id': _uuid.v4(),
        'family_id': familyId,
        'user_id': userId,
        'points': points,
        'reason': reason,
        'task_id': taskId,
        'task_title': taskTitle,
        'created_at': now.toIso8601String(),
      };

      await _supabase.from('points_history').insert(historyData);
    } catch (e) {
      _logger.e('Log points transaction error: $e');
      // Don't rethrow - points history logging shouldn't break the app
    }
  }

  /// Get points history for a user
  Future<List<PointsHistoryModel>> getPointsHistoryForUser({
    required String userId,
    required String familyId,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('points_history')
          .select()
          .eq('family_id', familyId)
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => PointsHistoryModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get points history error: $e');
      rethrow;
    }
  }

  /// Get points history for all family members
  Future<List<PointsHistoryModel>> getPointsHistoryForFamily({
    required String familyId,
    int? limit,
  }) async {
    try {
      var query = _supabase
          .from('points_history')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List)
          .map((json) => PointsHistoryModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get family points history error: $e');
      rethrow;
    }
  }
}

