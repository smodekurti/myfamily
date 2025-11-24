import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/task_model.dart';

class TaskRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

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

      _logger.i('Task created successfully: ${response['id']}');
      return TaskModelHelpers.fromSupabase(response);
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
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (status != null) updates['status'] = status;
      if (priority != null) updates['priority'] = priority;
      if (category != null) updates['category'] = category;
      if (categoryData != null) updates['category_data'] = categoryData;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (points != null) updates['points'] = points;

      // If marking as completed, set completed_at
      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
      }

      final response = await _supabase
          .from('tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      _logger.i('Task updated successfully: $taskId');
      return TaskModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Update task error: $e');
      rethrow;
    }
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _supabase
          .from('tasks')
          .delete()
          .eq('id', taskId);

      _logger.i('Task deleted successfully: $taskId');
    } catch (e) {
      _logger.e('Delete task error: $e');
      rethrow;
    }
  }

  /// Get tasks for a specific family
  Future<List<TaskModel>> getTasksForFamily(String familyId) async {
    try {
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
  Future<List<TaskModel>> getTasksForUser(String userId, String familyId) async {
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
  Future<List<TaskModel>> getTasksDueToday(String familyId) async {
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
        final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return due == today;
      }).toList();
    } catch (e) {
      _logger.e('Get tasks due today error: $e');
      rethrow;
    }
  }

  /// Stream tasks for a specific family (real-time updates)
  Stream<List<TaskModel>> streamTasksForFamily(String familyId) {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => TaskModelHelpers.fromSupabase(json)).toList());
  }

  /// Stream tasks assigned to a specific user
  Stream<List<TaskModel>> streamTasksForUser(String userId, String familyId) {
    // For now, return a stream that filters family tasks for the user
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((data) => data
            .where((json) => json['assigned_to'] == userId)
            .map((json) => TaskModelHelpers.fromSupabase(json))
            .toList());
  }

  /// Mark a task as completed and award points
  Future<TaskModel> completeTask(String taskId) async {
    try {
      // First get the task to get the points
      final taskResponse = await _supabase
          .from('tasks')
          .select('points')
          .eq('id', taskId)
          .single();

      final points = taskResponse['points'] as int;

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

      _logger.i('Task completed successfully: $taskId, points awarded: $points');
      
      // TODO: Award points to user (will implement with gamification)
      // await _awardPointsToUser(assignedTo, points);

      return TaskModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Complete task error: $e');
      rethrow;
    }
  }

  /// Get upcoming tasks (future dates, not completed)
  Stream<List<TaskModel>> getUpcomingTasks(String familyId) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    
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
                return due.isAfter(startOfTomorrow.subtract(const Duration(seconds: 1)));
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
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
      };
    }
  }
}
