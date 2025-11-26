import '../../data/models/task_model.dart';

/// Utility class for calculating task completion streaks
class StreakCalculator {
  /// Calculate streak information from completed tasks
  /// Returns a map with 'currentStreak' and 'longestStreak'
  static Map<String, int> calculateStreaks(List<TaskModel> completedTasks) {
    if (completedTasks.isEmpty) {
      return {'currentStreak': 0, 'longestStreak': 0};
    }

    // Get unique completion dates (normalized to start of day)
    final completionDates = completedTasks
        .where((task) => task.completedAt != null)
        .map((task) {
          final date = task.completedAt;
          if (date == null) return null;
          return DateTime(date.year, date.month, date.day);
        })
        .whereType<DateTime>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending (most recent first)

    if (completionDates.isEmpty) {
      return {'currentStreak': 0, 'longestStreak': 0};
    }

    // Calculate current streak (consecutive days from today backwards)
    int currentStreak = 0;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    
    DateTime? expectedDate = todayStart;
    for (final date in completionDates) {
      if (expectedDate == null) break;
      if (date == expectedDate) {
        currentStreak++;
        expectedDate = expectedDate.subtract(const Duration(days: 1));
      } else if (date.isBefore(expectedDate)) {
        // Gap found, streak broken
        break;
      }
      // If date is after expected, skip it (shouldn't happen with sorted list)
    }

    // Calculate longest streak
    int longestStreak = 0;
    int tempStreak = 1;
    
    for (int i = 0; i < completionDates.length; i++) {
      if (i == 0) {
        longestStreak = 1;
        continue;
      }
      
      final daysDiff = completionDates[i - 1].difference(completionDates[i]).inDays;
      if (daysDiff == 1) {
        // Consecutive day
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        // Gap found, reset temp streak
        tempStreak = 1;
      }
    }

    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
    };
  }
}

