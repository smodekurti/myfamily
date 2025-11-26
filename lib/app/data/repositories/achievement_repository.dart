import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/achievement_model.dart';
import '../models/task_model.dart';
import 'points_history_repository.dart';

class AchievementRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();
  final PointsHistoryRepository _pointsHistoryRepo = PointsHistoryRepository();

  /// Check if user has unlocked an achievement
  Future<bool> hasAchievement({
    required String userId,
    required String familyId,
    required String achievementId,
  }) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select('id')
          .eq('user_id', userId)
          .eq('family_id', familyId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      _logger.e('Check achievement error: $e');
      return false;
    }
  }

  /// Unlock an achievement for a user
  Future<void> unlockAchievement({
    required String userId,
    required String familyId,
    required String achievementId,
  }) async {
    try {
      // Check if already unlocked
      final alreadyUnlocked = await hasAchievement(
        userId: userId,
        familyId: familyId,
        achievementId: achievementId,
      );

      if (alreadyUnlocked) {
        return; // Already unlocked
      }

      // Unlock the achievement
      final now = DateTime.now();
      final achievementData = {
        'id': _uuid.v4(),
        'user_id': userId,
        'family_id': familyId,
        'achievement_id': achievementId,
        'unlocked_at': now.toIso8601String(),
      };

      await _supabase.from('achievements').insert(achievementData);
      _logger.i('Unlocked achievement: $achievementId for user: $userId');
    } catch (e) {
      _logger.e('Unlock achievement error: $e');
      // Don't rethrow - achievement unlocking shouldn't break the app
    }
  }

  /// Get all unlocked achievements for a user
  Future<List<AchievementModel>> getUserAchievements({
    required String userId,
    required String familyId,
  }) async {
    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .eq('family_id', familyId)
          .order('unlocked_at', ascending: false);

      return (response as List)
          .map((json) => AchievementModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get user achievements error: $e');
      rethrow;
    }
  }

  /// Check and unlock achievements after task completion
  Future<void> checkAchievementsAfterTaskCompletion({
    required String userId,
    required String familyId,
    required TaskModel completedTask,
  }) async {
    try {
      // Get user's completed tasks count - query directly to avoid circular dependency
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .eq('assigned_to', userId)
          .eq('status', 'completed')
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);
      
      final completedTasks = (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();
      final taskCount = completedTasks.length;

      // Check first task achievement
      if (taskCount == 1) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.firstTask.id,
        );
      }

      // Check task count achievements
      if (taskCount == 10) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.taskMaster.id,
        );
      }

      if (taskCount == 50) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.taskExpert.id,
        );
      }

      // Check time-based achievements
      if (completedTask.completedAt != null) {
        final hour = completedTask.completedAt!.hour;
        if (hour < 8) {
          await unlockAchievement(
            userId: userId,
            familyId: familyId,
            achievementId: AchievementType.earlyBird.id,
          );
        }
        if (hour >= 22) {
          await unlockAchievement(
            userId: userId,
            familyId: familyId,
            achievementId: AchievementType.nightOwl.id,
          );
        }
      }

      // Check weekly achievement
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));
      final weeklyTasks = completedTasks.where((task) {
        if (task.completedAt == null) return false;
        return task.completedAt!.isAfter(weekAgo);
      }).toList();

      if (weeklyTasks.length == 5) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.weeklyWarrior.id,
        );
      }

      // Check points achievements
      final pointsHistory = await _pointsHistoryRepo.getPointsHistoryForUser(
        userId: userId,
        familyId: familyId,
      );
      final totalPoints = pointsHistory
          .where((entry) => entry.points > 0)
          .fold<int>(0, (sum, entry) => sum + entry.points);

      if (totalPoints >= 100 && totalPoints < 500) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.pointsCollector.id,
        );
      }

      if (totalPoints >= 500 && totalPoints < 1000) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.pointsChampion.id,
        );
      }

      if (totalPoints >= 1000) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.pointsLegend.id,
        );
      }
    } catch (e) {
      _logger.e('Check achievements after task completion error: $e');
      // Don't rethrow - achievement checking shouldn't break task completion
    }
  }

  /// Check streak achievements
  Future<void> checkStreakAchievements({
    required String userId,
    required String familyId,
    required int currentStreak,
  }) async {
    try {
      if (currentStreak >= 3) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.streakStarter.id,
        );
      }

      if (currentStreak >= 7) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.streakChampion.id,
        );
      }

      if (currentStreak >= 30) {
        await unlockAchievement(
          userId: userId,
          familyId: familyId,
          achievementId: AchievementType.streakLegend.id,
        );
      }
    } catch (e) {
      _logger.e('Check streak achievements error: $e');
      // Don't rethrow
    }
  }
}

