import 'package:logger/logger.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/family_repository.dart';

class FamilyDataService {
  final _logger = Logger();
  final TaskRepository _taskRepo = TaskRepository();
  final RewardRepository _rewardRepo = RewardRepository();
  final FamilyRepository _familyRepo = FamilyRepository();

  Future<Map<String, dynamic>> getWeeklyData(String familyId) async {
    try {
      final now = DateTime.now();
      final end = now;
      final start = now.subtract(const Duration(days: 7));

      // 1. Fetch Completed Tasks
      final tasks = await _taskRepo.getCompletedTasksInRange(
        familyId,
        start,
        end,
      );

      // 2. Fetch Redemptions
      final redemptions = await _rewardRepo.getRedemptionsInRange(
        familyId,
        start,
        end,
      );

      // 3. Fetch Members (for points context)
      final members = await _familyRepo.streamFamilyMembers(familyId).first;

      // 4. Process Data

      // Calculate Top Earner from tasks (approximation based on completed tasks in range)
      // Note: member.points is total balance, not weekly earnings.
      // So we sum up points from tasks completed in this range.
      final pointsEarned = <String, int>{};
      for (final task in tasks) {
        final uid = task.assignedTo;
        pointsEarned[uid] = (pointsEarned[uid] ?? 0) + task.points;
      }

      String topEarnerName = 'None';
      int maxPoints = -1;

      pointsEarned.forEach((uid, points) {
        if (points > maxPoints) {
          maxPoints = points;
          final member = members.firstWhere(
            (m) => m.uid == uid,
            orElse: () => members.first,
          );
          topEarnerName = member.displayName;
        }
      });

      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'top_earner': topEarnerName,
        'max_points': maxPoints > 0 ? maxPoints : 0,
        'tasks': tasks
            .map(
              (t) => {
                'title': t.title,
                'points': t.points,
                'category': t.category,
              },
            )
            .toList(),
        'redemptions': redemptions
            .map(
              (r) => {
                'reward': r.rewardTitle,
                'cost': r.costAtRedemption,
                'user': r.userName ?? 'someone',
              },
            )
            .toList(),
        'stats': {
          'total_tasks': tasks.length,
          'total_redemptions': redemptions.length,
        },
      };
    } catch (e) {
      _logger.e('Error gathering weekly data: $e');
      rethrow;
    }
  }
}
