import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/grocery_template_model.dart';

class GroceryListRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  /// Create a standalone grocery list (not attached to a task)
  Future<GroceryListModel> createStandaloneList({
    required String familyId,
    required String name,
    String? templateId,
    required String createdBy,
  }) async {
    try {
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

      _logger.i('Standalone grocery list created: ${response['id']}');
      return _fromSupabase(response);
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

      _logger.i('Grocery list created: ${response['id']}');
      return _fromSupabase(response);
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
  Stream<List<GroceryListModel>> streamStandaloneListsForFamily(String familyId) {
    return _supabase
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

      return _itemFromSupabase(response);
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

      return _itemFromSupabase(response);
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

      _logger.i('List name updated: $listId');
      return _fromSupabase(response);
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
  Future<void> deleteList(String listId) async {
    try {
      await _supabase
          .from('grocery_lists')
          .delete()
          .eq('id', listId);
      _logger.i('List deleted: $listId');
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

