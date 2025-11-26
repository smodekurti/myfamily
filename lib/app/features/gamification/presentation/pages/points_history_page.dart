import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/points_history_model.dart';

class PointsHistoryPage extends ConsumerWidget {
  const PointsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);

    if (currentUser == null || currentFamily == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Points History'),
        ),
        body: const Center(
          child: Text('Please select a family to view points history'),
        ),
      );
    }

    final pointsHistoryAsync = ref.watch(
      userPointsHistoryProvider((currentUser.id, currentFamily.id)),
    );

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Points History'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: pointsHistoryAsync.when(
            data: (history) {
              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: ResponsiveHelper.iconSize(64),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      SizedBox(height: ResponsiveHelper.h(16)),
                      Text(
                        'No points history yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      Text(
                        'Complete tasks to earn points!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Group by date
              final groupedHistory = <DateTime, List<PointsHistoryModel>>{};
              for (final entry in history) {
                if (entry.createdAt == null) continue;
                final date = DateTime(
                  entry.createdAt!.year,
                  entry.createdAt!.month,
                  entry.createdAt!.day,
                );
                groupedHistory.putIfAbsent(date, () => []).add(entry);
              }

              final sortedDates = groupedHistory.keys.toList()
                ..sort((a, b) => b.compareTo(a));

              return ListView.builder(
                padding: ResponsiveHelper.padding(all: 16),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates[index];
                  final entries = groupedHistory[date]!;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date header
                      Padding(
                        padding: ResponsiveHelper.padding(horizontal: 8, vertical: 12),
                        child: Text(
                          _formatDateHeader(date),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      // Entries for this date
                      ...entries.map((entry) => _buildHistoryItem(context, entry)),
                      SizedBox(height: ResponsiveHelper.h(8)),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveHelper.iconSize(64),
                    color: Theme.of(context).colorScheme.error,
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  Text(
                    'Error loading points history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(8)),
                  TextButton(
                    onPressed: () {
                      ref.invalidate(
                        userPointsHistoryProvider((currentUser.id, currentFamily.id)),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, PointsHistoryModel entry) {
    final isPositive = entry.points > 0;
    final reasonText = _getReasonText(entry.reason, entry.taskTitle);

    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.h(8)),
      child: ListTile(
        leading: Container(
          width: ResponsiveHelper.w(40),
          height: ResponsiveHelper.h(40),
          decoration: BoxDecoration(
            color: isPositive
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.errorContainer,
            borderRadius: ResponsiveHelper.borderRadius(20),
          ),
          child: Icon(
            isPositive ? Icons.add : Icons.remove,
            color: isPositive
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onErrorContainer,
            size: ResponsiveHelper.iconSize(20),
          ),
        ),
        title: Text(
          reasonText,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: entry.createdAt != null
            ? Text(
                DateFormat('h:mm a').format(entry.createdAt!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        trailing: Text(
          '${isPositive ? '+' : ''}${entry.points}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isPositive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM d, yyyy').format(date);
    }
  }

  String _getReasonText(String reason, String? taskTitle) {
    switch (reason) {
      case 'task_completed':
        return taskTitle != null ? 'Completed: $taskTitle' : 'Task completed';
      case 'task_uncompleted':
        return taskTitle != null ? 'Uncompleted: $taskTitle' : 'Task uncompleted';
      case 'bonus':
        return 'Bonus points';
      case 'streak_bonus':
        return 'Streak bonus';
      case 'weekly_bonus':
        return 'Weekly bonus';
      default:
        return 'Points earned';
    }
  }
}

