import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/grocery_template_model.dart';
import '../../core/services/family_notification_service.dart';
import '../../core/services/role_permission_service.dart';

class GroceryListRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final RolePermissionService _roleService = RolePermissionService();

  /// Create a standalone grocery list (not attached to a task)
  Future<GroceryListModel> createStandaloneList({
    required String familyId,
    required String name,
    String? templateId,
    required String createdBy,
  }) async {
    try {
      // Check permission to create lists
      final canCreate = await _roleService.canPerformAction(
        userId: createdBy,
        familyId: familyId,
        action: 'create_list',
      );
      
      if (!canCreate) {
        throw Exception('You do not have permission to create grocery lists');
      }
      
      final now = DateTime.now();
      final listData = {
        'task_id': null, // Standalone list
        'family_id': familyId,
        'name': name,
        'template_id': templateId,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_lists')
          .insert(listData)
          .select()
          .single();

      final createdList = _fromSupabase(response);
      _logger.i('Standalone grocery list created: ${createdList.id}');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryListChanged(
          familyId: familyId,
          action: 'created',
          listId: createdList.id,
          listName: name,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery list notification: $e');
      }

      return createdList;
    } catch (e) {
      _logger.e('Create standalone list error: $e');
      rethrow;
    }
  }

  /// Create a grocery list for a task
  Future<GroceryListModel> createList({
    required String taskId,
    required String familyId,
    required String name,
    String? templateId,
    required String createdBy,
  }) async {
    try {
      // Check permission to create lists
      final canCreate = await _roleService.canPerformAction(
        userId: createdBy,
        familyId: familyId,
        action: 'create_list',
      );
      
      if (!canCreate) {
        throw Exception('You do not have permission to create grocery lists');
      }
      
      final now = DateTime.now();
      final listData = {
        'task_id': taskId,
        'family_id': familyId,
        'name': name,
        'template_id': templateId,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_lists')
          .insert(listData)
          .select()
          .single();

      final createdList = _fromSupabase(response);
      _logger.i('Grocery list created: ${createdList.id}');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryListChanged(
          familyId: familyId,
          action: 'created',
          listId: createdList.id,
          listName: name,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery list notification: $e');
      }

      return createdList;
    } catch (e) {
      _logger.e('Create list error: $e');
      rethrow;
    }
  }

  /// Get all standalone grocery lists for a family
  Future<List<GroceryListModel>> getStandaloneListsForFamily(String familyId) async {
    try {
      final response = await _supabase
          .from('grocery_lists')
          .select()
          .eq('family_id', familyId)
          .isFilter('task_id', null)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => _fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get standalone lists error: $e');
      rethrow;
    }
  }

  /// Stream all standalone grocery lists for a family
  /// Children can now view and edit lists (permissions updated)
  Stream<List<GroceryListModel>> streamStandaloneListsForFamily(String familyId, {String? userId}) async* {
    try {
      yield* _supabase
          .from('grocery_lists')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) {
            // Filter out lists with task_id in memory
            return data
                .where((json) => json['task_id'] == null)
                .map((json) => _fromSupabase(json))
                .toList();
          })
          .map((lists) {
            // Sort by updated_at descending
            lists.sort((a, b) {
              final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1970);
              final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
            return lists;
          });
    } catch (e, stackTrace) {
      _logger.e('Error creating stream for standalone lists: $e', error: e, stackTrace: stackTrace);
      yield <GroceryListModel>[];
    }
  }

  /// Stream all grocery lists for a family (both standalone and task-linked)
  /// Children can now view and edit lists (permissions updated)
  Stream<List<GroceryListModel>> streamAllListsForFamily(String familyId, {String? userId}) async* {
    try {
      yield* _supabase
          .from('grocery_lists')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .map((data) {
            // Include all lists (both standalone and task-linked)
            return data
                .map((json) => _fromSupabase(json))
                .toList();
          })
          .map((lists) {
            // Sort by updated_at descending
            lists.sort((a, b) {
              final aDate = a.updatedAt ?? a.createdAt ?? DateTime(1970);
              final bDate = b.updatedAt ?? b.createdAt ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });
            return lists;
          });
    } catch (e, stackTrace) {
      _logger.e('Error creating stream for all lists: $e', error: e, stackTrace: stackTrace);
      yield <GroceryListModel>[];
    }
  }

  /// Get grocery list for a task
  Future<GroceryListModel?> getListForTask(String taskId) async {
    try {
      final response = await _supabase
          .from('grocery_lists')
          .select()
          .eq('task_id', taskId)
          .maybeSingle();

      if (response == null) return null;
      return _fromSupabase(response);
    } catch (e) {
      _logger.e('Get list error: $e');
      rethrow;
    }
  }

  /// Stream grocery list for a task
  Stream<GroceryListModel?> streamListForTask(String taskId) {
    return _supabase
        .from('grocery_lists')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .map((data) {
          if (data.isEmpty) return null;
          return _fromSupabase(data.first);
        });
  }

  /// Get grocery list by ID
  Future<GroceryListModel?> getListById(String listId) async {
    try {
      final response = await _supabase
          .from('grocery_lists')
          .select()
          .eq('id', listId)
          .maybeSingle();

      if (response == null) return null;
      return _fromSupabase(response);
    } catch (e) {
      _logger.e('Get list by ID error: $e');
      rethrow;
    }
  }

  /// Stream grocery list by ID
  Stream<GroceryListModel?> streamListById(String listId) {
    return _supabase
        .from('grocery_lists')
        .stream(primaryKey: ['id'])
        .eq('id', listId)
        .map((data) {
          if (data.isEmpty) return null;
          return _fromSupabase(data.first);
        });
  }

  /// Add item to grocery list
  Future<GroceryListItemModel> addItem({
    required String listId,
    required String name,
    required String category,
    int qty = 1,
    String? notes,
    String? unit,
    String? source,
  }) async {
    try {
      final now = DateTime.now();
      final itemData = {
        'list_id': listId,
        'name': name,
        'category': category,
        'qty': qty,
        'notes': notes,
        'unit': unit,
        'checked': false,
        'source': source,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_list_items')
          .insert(itemData)
          .select()
          .single();

      final createdItem = _itemFromSupabase(response);

      // NOTE: Not sending notification for adding items (nested event)
      // Notifications are only sent for top-level events (creating/updating/deleting lists)
      // Realtime streams will handle item updates automatically

      return createdItem;
    } catch (e) {
      _logger.e('Add item error: $e');
      rethrow;
    }
  }

  /// Get items for a grocery list
  Future<List<GroceryListItemModel>> getListItems(String listId) async {
    try {
      final response = await _supabase
          .from('grocery_list_items')
          .select()
          .eq('list_id', listId)
          .order('category', ascending: true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => _itemFromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get list items error: $e');
      rethrow;
    }
  }

  /// Stream items for a grocery list
  Stream<List<GroceryListItemModel>> streamListItems(String listId) {
    return _supabase
        .from('grocery_list_items')
        .stream(primaryKey: ['id'])
        .eq('list_id', listId)
        .order('category', ascending: true)
        .order('name', ascending: true)
        .map((data) => data.map((json) => _itemFromSupabase(json)).toList());
  }

  /// Get suggested items from previous completed lists
  /// Returns items that were checked in previous lists, ordered by frequency
  Future<List<Map<String, dynamic>>> getSuggestedItems(String familyId, {int limit = 20}) async {
    try {
      // Get all lists for the family
      final listsResponse = await _supabase
          .from('grocery_lists')
          .select('id')
          .eq('family_id', familyId);

      if (listsResponse.isEmpty) {
        return [];
      }

      final listIds = (listsResponse as List).map((list) => list['id'] as String).toList();

      // Get all checked items from these lists
      // Note: Supabase Flutter doesn't have inFilter, so we'll fetch all items and filter in memory
      final allItemsResponse = await _supabase
          .from('grocery_list_items')
          .select('list_id, name, category, unit, qty, checked')
          .eq('checked', true);
      
      // Filter items that belong to our lists
      final itemsResponse = allItemsResponse.where((item) {
        return listIds.contains(item['list_id'] as String);
      }).toList();

      if (itemsResponse.isEmpty) {
        return [];
      }

      // Count frequency of each item (by name and category)
      final itemCounts = <String, Map<String, dynamic>>{};
      
      for (final item in itemsResponse as List) {
        final name = (item['name'] as String).toLowerCase().trim();
        final category = (item['category'] as String).toLowerCase().trim();
        final key = '$name|$category';
        
        if (itemCounts.containsKey(key)) {
          itemCounts[key]!['count'] = (itemCounts[key]!['count'] as int) + 1;
        } else {
          itemCounts[key] = {
            'name': item['name'] as String,
            'category': item['category'] as String,
            'unit': item['unit'] as String?,
            'qty': item['qty'] as int? ?? 1,
            'count': 1,
          };
        }
      }

      // Convert to list and sort by frequency (most frequent first)
      final suggestions = itemCounts.values.toList();
      suggestions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Return top suggestions
      return suggestions.take(limit).toList();
    } catch (e) {
      _logger.e('Get suggested items error: $e');
      return [];
    }
  }

  /// Toggle item checked status
  Future<GroceryListItemModel> toggleItem(String itemId, bool checked) async {
    try {
      final updates = {
        'checked': checked,
        'checked_at': checked ? DateTime.now().toIso8601String() : null,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_list_items')
          .update(updates)
          .eq('id', itemId)
          .select()
          .single();

      final updatedItem = _itemFromSupabase(response);

      // NOTE: Not sending notification for item status changes (nested event)
      // Notifications are only sent for top-level events (creating/updating/deleting lists)
      // Realtime streams will handle item updates automatically

      return updatedItem;
    } catch (e) {
      _logger.e('Toggle item error: $e');
      rethrow;
    }
  }

  /// Update item
  Future<GroceryListItemModel> updateItem({
    required String itemId,
    String? name,
    String? category,
    int? qty,
    String? notes,
    String? unit,
  }) async {
    try {
      // Get item info first
      final itemResponse = await _supabase
          .from('grocery_list_items')
          .select('list_id')
          .eq('id', itemId)
          .single();
      final listId = itemResponse['list_id'] as String;
      
      // Get list to check permissions
      final list = await getListById(listId);
      if (list == null) {
        throw Exception('List not found');
      }
      
      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Check permission to edit lists
      final canEdit = await _roleService.canPerformAction(
        userId: userId,
        familyId: list.familyId,
        action: 'edit_list',
      );
      
      if (!canEdit) {
        throw Exception('You do not have permission to edit grocery list items');
      }
      
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (name != null) updates['name'] = name;
      if (category != null) updates['category'] = category;
      if (qty != null) updates['qty'] = qty;
      if (notes != null) updates['notes'] = notes;
      if (unit != null) updates['unit'] = unit;

      final response = await _supabase
          .from('grocery_list_items')
          .update(updates)
          .eq('id', itemId)
          .select()
          .single();

      return _itemFromSupabase(response);
    } catch (e) {
      _logger.e('Update item error: $e');
      rethrow;
    }
  }

  /// Delete item
  Future<void> deleteItem(String itemId) async {
    try {
      await _supabase
          .from('grocery_list_items')
          .delete()
          .eq('id', itemId);

      // NOTE: Not sending notification for deleting items (nested event)
      // Notifications are only sent for top-level events (creating/updating/deleting lists)
      // Realtime streams will handle item updates automatically
    } catch (e) {
      _logger.e('Delete item error: $e');
      rethrow;
    }
  }

  /// Update list name
  Future<GroceryListModel> updateListName({
    required String listId,
    required String name,
  }) async {
    try {
      final updates = {
        'name': name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_lists')
          .update(updates)
          .eq('id', listId)
          .select()
          .single();

      final updatedList = _fromSupabase(response);
      _logger.i('List name updated: $listId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryListChanged(
          familyId: updatedList.familyId,
          action: 'updated',
          listId: listId,
          listName: name,
          excludeUserId: updatedList.createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery list notification: $e');
      }

      return updatedList;
    } catch (e) {
      _logger.e('Update list name error: $e');
      rethrow;
    }
  }

  /// Update list task_id (link list to a task)
  Future<GroceryListModel> updateListTaskId({
    required String listId,
    required String taskId,
  }) async {
    try {
      final updates = {
        'task_id': taskId,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_lists')
          .update(updates)
          .eq('id', listId)
          .select()
          .single();

      _logger.i('List linked to task: $listId -> $taskId');
      return _fromSupabase(response);
    } catch (e) {
      _logger.e('Update list task_id error: $e');
      rethrow;
    }
  }

  /// Delete list
  /// If the list is referenced by tasks, creates a copy for each task before deleting
  Future<void> deleteList(String listId) async {
    try {
      // Check if list is referenced by any tasks via categoryData
      final list = await getListById(listId);
      if (list == null) {
        _logger.w('List not found: $listId');
        return;
      }

      // Find tasks that reference this list in their categoryData
      // Query all grocery tasks and filter in memory (Supabase JSONB queries are limited)
      final tasksResponse = await _supabase
          .from('tasks')
          .select('id, category_data')
          .eq('category', 'grocery');

      final tasksWithList = <String>[];
      for (final task in tasksResponse as List) {
        final categoryData = task['category_data'] as Map<String, dynamic>?;
        if (categoryData != null && categoryData['groceryListId'] == listId) {
          tasksWithList.add(task['id'] as String);
        }
      }

      // If list is referenced by tasks, create a copy for each task
      if (tasksWithList.isNotEmpty) {
        _logger.i('List $listId is referenced by ${tasksWithList.length} task(s). Creating copies...');
        
        // Get all items from the original list
        final originalItems = await getListItems(listId);
        
        // Create a copy for each task
        for (final taskId in tasksWithList) {
          // Create a new list for this task (copy)
          final copiedList = await createList(
            taskId: taskId,
            familyId: list.familyId,
            name: '${list.name} (Copy)',
            createdBy: list.createdBy,
          );
          
          // Copy all items to the new list
          for (final item in originalItems) {
            final newItem = await addItem(
              listId: copiedList.id,
              name: item.name,
              category: item.category,
              qty: item.qty,
              notes: item.notes,
              unit: item.unit,
              source: item.source ?? 'manual',
            );
            
            // If item was checked, mark it as checked in the copy
            if (item.checked) {
              await toggleItem(newItem.id, true);
            }
          }
          
          // Update the task's categoryData to point to the new list
          await _supabase
              .from('tasks')
              .update({
                'category_data': {'groceryListId': copiedList.id},
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', taskId);
          
          _logger.i('Created copy ${copiedList.id} for task $taskId');
        }
      }

      // Now safe to delete the original list
      await _supabase
          .from('grocery_lists')
          .delete()
          .eq('id', listId);
      _logger.i('List deleted: $listId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryListChanged(
          familyId: list.familyId,
          action: 'deleted',
          listId: listId,
          listName: list.name,
          excludeUserId: list.createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery list delete notification: $e');
      }
    } catch (e) {
      _logger.e('Delete list error: $e');
      rethrow;
    }
  }

  GroceryListModel _fromSupabase(Map<String, dynamic> json) {
    return GroceryListModel(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      familyId: json['family_id'] as String,
      name: json['name'] as String,
      templateId: json['template_id'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  GroceryListItemModel _itemFromSupabase(Map<String, dynamic> json) {
    return GroceryListItemModel(
      id: json['id'] as String,
      listId: json['list_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      qty: json['qty'] as int? ?? 1,
      notes: json['notes'] as String?,
      unit: json['unit'] as String?,
      checked: json['checked'] as bool? ?? false,
      checkedAt: json['checked_at'] != null
          ? DateTime.parse(json['checked_at'] as String)
          : null,
      source: json['source'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

