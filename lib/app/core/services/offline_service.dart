import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class OfflineService {
  final Logger _logger = Logger();
  static const String _tasksKey = 'offline_tasks';
  static const String _groceryListsKey = 'offline_grocery_lists';
  static const String _eventsKey = 'offline_events';
  static const String _pendingOperationsKey = 'pending_operations';

  /// Save tasks to local storage
  Future<void> cacheTasks(List<Map<String, dynamic>> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tasksKey, jsonEncode(tasks));
      _logger.i('Tasks cached offline: ${tasks.length}');
    } catch (e) {
      _logger.e('Cache tasks error: $e');
    }
  }

  /// Get cached tasks from local storage
  Future<List<Map<String, dynamic>>> getCachedTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getString(_tasksKey);
      if (tasksJson != null) {
        final tasks = (jsonDecode(tasksJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
        _logger.i('Retrieved ${tasks.length} cached tasks');
        return tasks;
      }
    } catch (e) {
      _logger.e('Get cached tasks error: $e');
    }
    return [];
  }

  /// Save grocery lists to local storage
  Future<void> cacheGroceryLists(List<Map<String, dynamic>> lists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_groceryListsKey, jsonEncode(lists));
      _logger.i('Grocery lists cached offline: ${lists.length}');
    } catch (e) {
      _logger.e('Cache grocery lists error: $e');
    }
  }

  /// Get cached grocery lists from local storage
  Future<List<Map<String, dynamic>>> getCachedGroceryLists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listsJson = prefs.getString(_groceryListsKey);
      if (listsJson != null) {
        final lists = (jsonDecode(listsJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
        _logger.i('Retrieved ${lists.length} cached grocery lists');
        return lists;
      }
    } catch (e) {
      _logger.e('Get cached grocery lists error: $e');
    }
    return [];
  }

  /// Save events to local storage
  Future<void> cacheEvents(List<Map<String, dynamic>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_eventsKey, jsonEncode(events));
      _logger.i('Events cached offline: ${events.length}');
    } catch (e) {
      _logger.e('Cache events error: $e');
    }
  }

  /// Get cached events from local storage
  Future<List<Map<String, dynamic>>> getCachedEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_eventsKey);
      if (eventsJson != null) {
        final events = (jsonDecode(eventsJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
        _logger.i('Retrieved ${events.length} cached events');
        return events;
      }
    } catch (e) {
      _logger.e('Get cached events error: $e');
    }
    return [];
  }

  /// Add a pending operation (for sync when online)
  Future<void> addPendingOperation({
    required String type, // 'create_task', 'update_task', 'complete_task', etc.
    required Map<String, dynamic> data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingOperationsKey);
      final pending = pendingJson != null
          ? (jsonDecode(pendingJson) as List).cast<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      
      pending.add({
        'type': type,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      await prefs.setString(_pendingOperationsKey, jsonEncode(pending));
      _logger.i('Added pending operation: $type');
    } catch (e) {
      _logger.e('Add pending operation error: $e');
    }
  }

  /// Get all pending operations
  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingOperationsKey);
      if (pendingJson != null) {
        return (jsonDecode(pendingJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
      }
    } catch (e) {
      _logger.e('Get pending operations error: $e');
    }
    return [];
  }

  /// Clear pending operations
  Future<void> clearPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_pendingOperationsKey);
      _logger.i('Cleared pending operations');
    } catch (e) {
      _logger.e('Clear pending operations error: $e');
    }
  }

  /// Remove a specific pending operation
  Future<void> removePendingOperation(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingOperationsKey);
      if (pendingJson != null) {
        final pending = (jsonDecode(pendingJson) as List)
            .cast<Map<String, dynamic>>()
            .toList();
        if (index >= 0 && index < pending.length) {
          pending.removeAt(index);
          await prefs.setString(_pendingOperationsKey, jsonEncode(pending));
        }
      }
    } catch (e) {
      _logger.e('Remove pending operation error: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tasksKey);
      await prefs.remove(_groceryListsKey);
      await prefs.remove(_eventsKey);
      _logger.i('Cleared all cached data');
    } catch (e) {
      _logger.e('Clear cache error: $e');
    }
  }
}

