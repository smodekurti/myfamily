import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/task_model.dart';
import 'family_repository.dart';
import 'achievement_repository.dart';
import '../../core/utils/streak_calculator.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/family_notification_service.dart';
import '../../core/services/role_permission_service.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final FamilyRepository _familyRepo = FamilyRepository();
  final AchievementRepository _achievementRepo = AchievementRepository();
  final RolePermissionService _roleService = RolePermissionService();

  /// Create a new task
  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String assignedTo,
    required String createdBy,
    required String familyId,
    String status = 'pending',
    String priority = 'medium',
    String category = 'chore',
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int points = 10,
  }) async {
    try {
      // Check permission to create tasks
      final canCreate = await _roleService.canPerformAction(
        userId: createdBy,
        familyId: familyId,
        action: 'create_task',
      );

      if (!canCreate) {
        throw Exception('You do not have permission to create tasks');
      }

      // Check permission to assign tasks if assigning to someone else
      if (assignedTo != createdBy) {
        final canAssign = await _roleService.canPerformAction(
          userId: createdBy,
          familyId: familyId,
          action: 'assign_task',
        );

        if (!canAssign) {
          throw Exception(
            'You do not have permission to assign tasks to others',
          );
        }
      }

      final now = DateTime.now();

      final taskData = {
        'family_id': familyId,
        'title': title,
        'description': description,
        'assigned_to': assignedTo,
        'created_by': createdBy,
        'status': status,
        'priority': priority,
        'category': category,
        'category_data': categoryData,
        'due_date': dueDate?.toIso8601String(),
        'points': points,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('tasks')
          .insert(taskData)
          .select()
          .single();

      final createdTask = TaskModelHelpers.fromSupabase(response);

      // Send notifications to family members
      try {
        // Send visible notification to assignee (if different from creator)
        if (assignedTo != createdBy) {
          await FamilyNotificationService().notifyTaskAssigned(
            familyId: familyId,
            assigneeId: assignedTo,
            taskId: createdTask.id,
            taskTitle: title,
            createdById: createdBy,
          );
        }

        // Send silent notification to all other family members to trigger refresh
        await FamilyNotificationService().notifyFamilyDataChanged(
          familyId: familyId,
          dataType: 'task',
          action: 'created',
          itemId: createdTask.id,
          itemTitle: title,
          excludeUserId: createdBy,
        );
      } catch (e) {
        // Don't fail task creation if notifications fail
      }

      // Schedule due date reminder if due date is set
      if (dueDate != null) {
        try {
          await NotificationService().scheduleTaskDueReminder(
            taskId: createdTask.id,
            taskTitle: title,
            dueDate: dueDate,
          );
        } catch (e) {}
      }

      return createdTask;
    } catch (e) {
      _logger.e('Create task error: $e');
      rethrow;
    }
  }

  /// Update an existing task
  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    String? status,
    String? priority,
    String? category,
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int? points,
  }) async {
    try {
      // Get current task state to handle points properly
      final currentTaskResponse = await _supabase
          .from('tasks')
          .select('status, points, assigned_to, family_id')
          .eq('id', taskId)
          .single();

      final currentStatus = currentTaskResponse['status'] as String;
      final taskPoints = currentTaskResponse['points'] as int;
      final taskAssignedTo = currentTaskResponse['assigned_to'] as String;
      final taskFamilyId = currentTaskResponse['family_id'] as String;

      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check permission to edit tasks
      final canEdit = await _roleService.canPerformAction(
        userId: userId,
        familyId: taskFamilyId,
        action: 'edit_task',
      );

      if (!canEdit) {
        throw Exception('You do not have permission to edit tasks');
      }

      // Check permission to assign tasks if reassigning
      if (assignedTo != null &&
          assignedTo != taskAssignedTo &&
          assignedTo != userId) {
        final canAssign = await _roleService.canPerformAction(
          userId: userId,
          familyId: taskFamilyId,
          action: 'assign_task',
        );

        if (!canAssign) {
          throw Exception(
            'You do not have permission to assign tasks to others',
          );
        }
      }

      // Handle points when status changes
      if (status != null) {
        // Get task title for history
        final taskTitleResponse = await _supabase
            .from('tasks')
            .select('title')
            .eq('id', taskId)
            .single();
        final taskTitle = taskTitleResponse['title'] as String?;

        if (status == 'completed' && currentStatus != 'completed') {
          // Task is being marked as complete - award points
          await _familyRepo.awardPointsToMember(
            familyId: taskFamilyId,
            userId: taskAssignedTo,
            points: taskPoints,
            reason: 'task_completed',
            taskId: taskId,
            taskTitle: taskTitle,
          );
        } else if (status != 'completed' && currentStatus == 'completed') {
          // Task is being uncompleted - remove points
          await _familyRepo.removePointsFromMember(
            familyId: taskFamilyId,
            userId: taskAssignedTo,
            points: taskPoints,
            reason: 'task_uncompleted',
            taskId: taskId,
            taskTitle: taskTitle,
          );
        }
      }

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (status != null) updates['status'] = status;
      if (priority != null) updates['priority'] = priority;
      if (category != null) updates['category'] = category;
      // Handle categoryData: if it's an empty map, set to null to clear it
      // Otherwise, update it if provided
      if (categoryData != null) {
        if (categoryData.isEmpty) {
          updates['category_data'] = null;
        } else {
          updates['category_data'] = categoryData;
        }
      }
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (points != null) updates['points'] = points;

      // If marking as completed, set completed_at
      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      } else if (status != null && status != 'completed') {
        // If uncompleting, clear completed_at
        updates['completed_at'] = null;
      }

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      final updatedTask = TaskModelHelpers.fromSupabase(response);

      // Handle notifications for task updates
      try {
        // If assignee changed, notify new assignee
        if (assignedTo != null && assignedTo != taskAssignedTo) {
          // Get family ID from the task
          final taskFamilyId = updatedTask.familyId;
          await FamilyNotificationService().notifyTaskAssigned(
            familyId: taskFamilyId,
            assigneeId: assignedTo,
            taskId: taskId,
            taskTitle: updatedTask.title,
            createdById: updatedTask.createdBy,
          );
        }

        // Send silent notification to all family members about the update
        await FamilyNotificationService().notifyFamilyDataChanged(
          familyId: updatedTask.familyId,
          dataType: 'task',
          action: 'updated',
          itemId: taskId,
          itemTitle: updatedTask.title,
          excludeUserId: updatedTask.createdBy,
        );

        // If due date changed, update reminder
        if (dueDate != null) {
          // Cancel old reminder
          await NotificationService().cancelTaskNotifications(taskId);
          // Schedule new reminder
          await NotificationService().scheduleTaskDueReminder(
            taskId: taskId,
            taskTitle: updatedTask.title,
            dueDate: dueDate,
          );
        } else if (dueDate == null && updates.containsKey('due_date')) {
          // Due date was removed, cancel reminder
          await NotificationService().cancelTaskNotifications(taskId);
        }
      } catch (e) {}

      return updatedTask;
    } catch (e) {
      _logger.e('Update task error: $e');
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      // Get task info before deleting for notifications
      final taskResponse = await _supabase
          .from('tasks')
          .select('family_id, title, created_by')
          .eq('id', taskId)
          .single();
      final familyId = taskResponse['family_id'] as String;
      final taskTitle = taskResponse['title'] as String;
      final createdBy = taskResponse['created_by'] as String;

      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check permission to delete tasks
      final canDelete = await _roleService.canPerformAction(
        userId: userId,
        familyId: familyId,
        action: 'delete_task',
      );

      if (!canDelete) {
        throw Exception('You do not have permission to delete tasks');
      }

      await _supabase.from('tasks').delete().eq('id', taskId);

      // Notify family members about deletion
      try {
        await FamilyNotificationService().notifyFamilyDataChanged(
          familyId: familyId,
          dataType: 'task',
          action: 'deleted',
          itemId: taskId,
          itemTitle: taskTitle,
          excludeUserId: createdBy,
        );
      } catch (e) {}
    } catch (e) {
      _logger.e('Delete task error: $e');
      rethrow;
    }
  }

  /// Get tasks for a specific family
  /// Children can now view all tasks (permissions updated)
  Future<List<TaskModel>> getTasksForFamily(
    String familyId, {
    String? userId,
  }) async {
    try {
      // Return all family tasks for all roles
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get tasks for family error: $e');
      rethrow;
    }
  }

  /// Get tasks assigned to a specific user
  Future<List<TaskModel>> getTasksForUser(
    String userId,
    String familyId,
  ) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .eq('assigned_to', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get tasks for user error: $e');
      rethrow;
    }
  }

  /// Get tasks due today
  /// Children can now view all tasks (permissions updated)
  Future<List<TaskModel>> getTasksDueToday(
    String familyId, {
    String? userId,
  }) async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfDay = today.toIso8601String();
      final endOfDay = today.add(const Duration(days: 1)).toIso8601String();

      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .gte('due_date', startOfDay)
          .lt('due_date', endOfDay)
          .neq('status', 'completed')
          .order('due_date', ascending: true);

      // Also filter in memory to ensure we only get tasks due today (handles timezone issues)
      final allTasks = (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();

      return allTasks.where((task) {
        if (task.dueDate == null) return false;
        final due = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        return due == today;
      }).toList();
    } catch (e) {
      _logger.e('Get tasks due today error: $e');
      rethrow;
    }
  }

  /// Stream tasks for a specific family (real-time updates)
  /// Stream tasks for a specific family
  /// Children can now view all tasks (permissions updated)
  Stream<List<TaskModel>> streamTasksForFamily(
    String familyId, {
    String? userId,
  }) async* {
    try {
      // Stream all family tasks for all roles
      yield* _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .map(
            (data) => data
                .map((json) => TaskModelHelpers.fromSupabase(json))
                .toList(),
          );
    } catch (e, stackTrace) {
      _logger.e(
        'Error creating stream for family tasks: $e',
        error: e,
        stackTrace: stackTrace,
      );
      yield <TaskModel>[];
    }
  }

  /// Stream tasks assigned to a specific user
  Stream<List<TaskModel>> streamTasksForUser(String userId, String familyId) {
    try {
      // Stream all family tasks and filter for the user
      return _supabase
          .from('tasks')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .map((data) {
            try {
              final tasks = data
                  .where((json) => json['assigned_to'] == userId)
                  .map((json) => TaskModelHelpers.fromSupabase(json))
                  .toList();
              return tasks;
            } catch (e, stackTrace) {
              _logger.e(
                'Error parsing user tasks from stream: $e',
                error: e,
                stackTrace: stackTrace,
              );
              return <TaskModel>[];
            }
          })
          .handleError((error, stackTrace) {
            _logger.e(
              'Stream error for user tasks: $error',
              error: error,
              stackTrace: stackTrace,
            );
            // Log error but don't close the stream - it will automatically reconnect
          });
    } catch (e, stackTrace) {
      _logger.e(
        'Error creating stream for user tasks: $e',
        error: e,
        stackTrace: stackTrace,
      );
      return Stream.value(<TaskModel>[]);
    }
  }

  /// Get completed tasks for a user to calculate streaks
  Future<List<TaskModel>> getCompletedTasksForUser(
    String userId,
    String familyId,
  ) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .eq('assigned_to', userId)
          .eq('status', 'completed')
          .not('completed_at', 'is', null)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get completed tasks for user error: $e');
      rethrow;
    }
  }

  /// Get completed tasks for a family within a date range
  Future<List<TaskModel>> getCompletedTasksInRange(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select()
          .eq('family_id', familyId)
          .eq('status', 'completed')
          .gte('completed_at', start.toIso8601String())
          .lte('completed_at', end.toIso8601String())
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => TaskModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get completed tasks in range error: $e');
      rethrow;
    }
  }

  /// Mark a task as completed and award points
  Future<TaskModel> completeTask(String taskId) async {
    try {
      // First get the full task to check for recurrence
      final taskResponse = await _supabase
          .from('tasks')
          .select('*')
          .eq('id', taskId)
          .single();

      final points = taskResponse['points'] as int;
      final assignedTo = taskResponse['assigned_to'] as String;
      final familyId = taskResponse['family_id'] as String;
      final currentStatus = taskResponse['status'] as String;
      final categoryData =
          taskResponse['category_data'] as Map<String, dynamic>?;
      final dueDate = taskResponse['due_date'] != null
          ? DateTime.parse(taskResponse['due_date'] as String)
          : null;

      // Only award points if task wasn't already completed
      if (currentStatus != 'completed') {
        final taskTitle = taskResponse['title'] as String?;
        // Award points to the assigned user
        await _familyRepo.awardPointsToMember(
          familyId: familyId,
          userId: assignedTo,
          points: points,
          reason: 'task_completed',
          taskId: taskId,
          taskTitle: taskTitle,
        );
      }

      // Update the task status
      final now = DateTime.now();
      final updates = {
        'status': 'completed',
        'completed_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      // Check and unlock achievements
      final completedTask = TaskModelHelpers.fromSupabase(response);
      await _achievementRepo.checkAchievementsAfterTaskCompletion(
        userId: assignedTo,
        familyId: familyId,
        completedTask: completedTask,
      );

      // Check streak achievements
      final completedTasks = await getCompletedTasksForUser(
        assignedTo,
        familyId,
      );
      final streaks = StreakCalculator.calculateStreaks(completedTasks);
      final currentStreak = streaks['currentStreak'] ?? 0;
      await _achievementRepo.checkStreakAchievements(
        userId: assignedTo,
        familyId: familyId,
        currentStreak: currentStreak,
      );

      // Cancel due date reminder since task is completed
      try {
        await NotificationService().cancelTaskNotifications(taskId);
      } catch (e) {}

      // Check if this is a recurring task and create the next occurrence
      if (categoryData != null && categoryData['recurrenceType'] != null) {
        final recurrenceType = categoryData['recurrenceType'] as String;
        if (recurrenceType != 'none') {
          await _createNextRecurrence(
            originalTask: TaskModelHelpers.fromSupabase(taskResponse),
            recurrenceType: recurrenceType,
            recurrenceEndDate: categoryData['recurrenceEndDate'] != null
                ? DateTime.parse(categoryData['recurrenceEndDate'] as String)
                : null,
            originalDueDate: dueDate,
          );
        }
      }

      return TaskModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Complete task error: $e');
      rethrow;
    }
  }

  /// Create the next occurrence of a recurring task
  Future<void> _createNextRecurrence({
    required TaskModel originalTask,
    required String recurrenceType,
    DateTime? recurrenceEndDate,
    DateTime? originalDueDate,
  }) async {
    try {
      // Calculate next due date based on recurrence type
      DateTime? nextDueDate;
      if (originalDueDate != null) {
        switch (recurrenceType) {
          case 'daily':
            nextDueDate = originalDueDate.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDueDate = originalDueDate.add(const Duration(days: 7));
            break;
          case 'monthly':
            // Add one month
            nextDueDate = DateTime(
              originalDueDate.year,
              originalDueDate.month + 1,
              originalDueDate.day,
            );
            break;
        }
      } else {
        // If no original due date, use today + recurrence interval
        final today = DateTime.now();
        switch (recurrenceType) {
          case 'daily':
            nextDueDate = today.add(const Duration(days: 1));
            break;
          case 'weekly':
            nextDueDate = today.add(const Duration(days: 7));
            break;
          case 'monthly':
            nextDueDate = DateTime(today.year, today.month + 1, today.day);
            break;
        }
      }

      // Check if we've passed the recurrence end date
      if (recurrenceEndDate != null && nextDueDate != null) {
        if (nextDueDate.isAfter(recurrenceEndDate)) {
          return;
        }
      }

      // Create the next occurrence
      final now = DateTime.now();
      final nextCategoryData = Map<String, dynamic>.from(
        originalTask.categoryData ?? {},
      );

      final nextTaskData = {
        'family_id': originalTask.familyId,
        'title': originalTask.title,
        'description': originalTask.description,
        'assigned_to': originalTask.assignedTo,
        'created_by': originalTask.createdBy,
        'status': 'pending',
        'priority': originalTask.priority,
        'category': originalTask.category,
        'category_data': nextCategoryData,
        'due_date': nextDueDate?.toIso8601String(),
        'points': originalTask.points,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      await _supabase.from('tasks').insert(nextTaskData);
    } catch (e) {
      _logger.e('Error creating next recurrence: $e');
      // Don't rethrow - we don't want to fail task completion if recurrence creation fails
    }
  }

  /// Get upcoming tasks (future dates, not completed)
  Stream<List<TaskModel>> getUpcomingTasks(String familyId) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
    );

    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('due_date', ascending: true)
        .map((data) {
          return data
              .where((json) {
                final dueDate = json['due_date'] as String?;
                final status = json['status'] as String?;
                if (dueDate == null || status == 'completed') return false;
                final due = DateTime.parse(dueDate);
                return due.isAfter(
                  startOfTomorrow.subtract(const Duration(seconds: 1)),
                );
              })
              .map((json) => TaskModelHelpers.fromSupabase(json))
              .toList();
        });
  }

  /// Get task statistics for a family
  Future<Map<String, int>> getTaskStats(String familyId) async {
    try {
      final response = await _supabase
          .from('tasks')
          .select('status')
          .eq('family_id', familyId);

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
      };

      for (final task in response as List) {
        final status = task['status'] as String;
        stats['total'] = (stats['total'] ?? 0) + 1;
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      _logger.e('Get task stats error: $e');
      return {'total': 0, 'pending': 0, 'in_progress': 0, 'completed': 0};
    }
  }
}
