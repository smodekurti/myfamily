import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/grocery_template_model.dart';
import '../../core/services/family_notification_service.dart';

class GroceryTemplateRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  /// Check if a template name already exists for a family
  Future<bool> templateNameExists(String familyId, String name) async {
    try {
      final response = await _supabase
          .from('grocery_templates')
          .select('id')
          .eq('family_id', familyId)
          .eq('name', name.trim())
          .limit(1);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      _logger.e('Check template name error: $e');
      return false; // Return false on error to allow creation
    }
  }

  /// Create a grocery template
  Future<GroceryTemplateModel> createTemplate({
    required String familyId,
    required String name,
    String? icon,
    String? color,
    required String createdBy,
  }) async {
    try {
      // Check if template name already exists
      final nameExists = await templateNameExists(familyId, name);
      if (nameExists) {
        throw Exception('A template with the name "$name" already exists for this family.');
      }

      final now = DateTime.now();
      final templateData = {
        'family_id': familyId,
        'name': name.trim(),
        'icon': icon,
        'color': color,
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_templates')
          .insert(templateData)
          .select()
          .single();

      final createdTemplate = _fromSupabase(response);
      _logger.i('Grocery template created: ${createdTemplate.id}');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryTemplateChanged(
          familyId: familyId,
          action: 'created',
          templateId: createdTemplate.id,
          templateName: name,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery template notification: $e');
      }

      return createdTemplate;
    } catch (e) {
      _logger.e('Create template error: $e');
      rethrow;
    }
  }

  /// Get all templates for a family
  Future<List<GroceryTemplateModel>> getTemplatesForFamily(String familyId) async {
    try {
      final response = await _supabase
          .from('grocery_templates')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => _fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get templates error: $e');
      rethrow;
    }
  }

  /// Stream templates for a family
  Stream<List<GroceryTemplateModel>> streamTemplatesForFamily(String familyId) {
    return _supabase
        .from('grocery_templates')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => _fromSupabase(json)).toList());
  }

  /// Create template item
  Future<GroceryTemplateItemModel> createTemplateItem({
    required String templateId,
    required String name,
    required String category,
    int defaultQty = 1,
    String? notes,
    String? unit,
  }) async {
    try {
      final now = DateTime.now();
      final itemData = {
        'template_id': templateId,
        'name': name,
        'category': category,
        'default_qty': defaultQty,
        'notes': notes,
        'unit': unit,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_template_items')
          .insert(itemData)
          .select()
          .single();

      return _itemFromSupabase(response);
    } catch (e) {
      _logger.e('Create template item error: $e');
      rethrow;
    }
  }

  /// Get items for a template
  Future<List<GroceryTemplateItemModel>> getTemplateItems(String templateId) async {
    try {
      final response = await _supabase
          .from('grocery_template_items')
          .select()
          .eq('template_id', templateId)
          .order('category', ascending: true)
          .order('name', ascending: true);

      return (response as List)
          .map((json) => _itemFromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get template items error: $e');
      rethrow;
    }
  }

  /// Stream template items
  Stream<List<GroceryTemplateItemModel>> streamTemplateItems(String templateId) {
    return _supabase
        .from('grocery_template_items')
        .stream(primaryKey: ['id'])
        .eq('template_id', templateId)
        .order('category', ascending: true)
        .order('name', ascending: true)
        .map((data) => data.map((json) => _itemFromSupabase(json)).toList());
  }

  /// Delete template item
  Future<void> deleteTemplateItem(String itemId) async {
    try {
      await _supabase
          .from('grocery_template_items')
          .delete()
          .eq('id', itemId);
      _logger.i('Template item deleted: $itemId');
    } catch (e) {
      _logger.e('Delete template item error: $e');
      rethrow;
    }
  }

  /// Create template from a grocery list
  Future<GroceryTemplateModel> createTemplateFromList({
    required String familyId,
    required String name,
    required String createdBy,
    required List<Map<String, dynamic>> items, // List of items with name, category, qty, notes, unit
  }) async {
    try {
      // Check if template name already exists
      final nameExists = await templateNameExists(familyId, name);
      if (nameExists) {
        throw Exception('A template with the name "$name" already exists for this family.');
      }

      final now = DateTime.now();
      final templateData = {
        'family_id': familyId,
        'name': name.trim(),
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final templateResponse = await _supabase
          .from('grocery_templates')
          .insert(templateData)
          .select()
          .single();

      final templateId = templateResponse['id'] as String;

      // Insert template items
      if (items.isNotEmpty) {
        final itemsData = items.map((item) => {
          'template_id': templateId,
          'name': item['name'] as String,
          'category': item['category'] as String,
          'default_qty': item['qty'] as int? ?? 1,
          'notes': item['notes'] as String?,
          'unit': item['unit'] as String?,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }).toList();

        await _supabase
            .from('grocery_template_items')
            .insert(itemsData);
      }

      final createdTemplate = _fromSupabase(templateResponse);
      _logger.i('Template created from list: $templateId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryTemplateChanged(
          familyId: familyId,
          action: 'created',
          templateId: createdTemplate.id,
          templateName: name,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery template notification: $e');
      }

      return createdTemplate;
    } catch (e) {
      _logger.e('Create template from list error: $e');
      rethrow;
    }
  }

  /// Update template name
  Future<GroceryTemplateModel> updateTemplate({
    required String templateId,
    required String familyId,
    required String name,
  }) async {
    try {
      // Get current template to check if name is actually changing
      final currentTemplate = await _supabase
          .from('grocery_templates')
          .select('name')
          .eq('id', templateId)
          .single();
      
      final currentName = currentTemplate['name'] as String;
      
      // Only check for duplicates if the name is actually changing
      if (currentName.trim().toLowerCase() != name.trim().toLowerCase()) {
        final nameExists = await templateNameExists(familyId, name);
        if (nameExists) {
          throw Exception('A template with the name "$name" already exists for this family.');
        }
      }

      final updates = {
        'name': name.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('grocery_templates')
          .update(updates)
          .eq('id', templateId)
          .select()
          .single();

      final updatedTemplate = _fromSupabase(response);
      _logger.i('Template updated: $templateId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryTemplateChanged(
          familyId: familyId,
          action: 'updated',
          templateId: templateId,
          templateName: name,
          excludeUserId: updatedTemplate.createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery template notification: $e');
      }

      return updatedTemplate;
    } catch (e) {
      _logger.e('Update template error: $e');
      rethrow;
    }
  }

  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    try {
      // Get template info before deleting
      final template = await _supabase
          .from('grocery_templates')
          .select('family_id, name, created_by')
          .eq('id', templateId)
          .single();
      final familyId = template['family_id'] as String;
      final templateName = template['name'] as String;
      final createdBy = template['created_by'] as String;

      await _supabase
          .from('grocery_templates')
          .delete()
          .eq('id', templateId);
      _logger.i('Template deleted: $templateId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyGroceryTemplateChanged(
          familyId: familyId,
          action: 'deleted',
          templateId: templateId,
          templateName: templateName,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send grocery template delete notification: $e');
      }
    } catch (e) {
      _logger.e('Delete template error: $e');
      rethrow;
    }
  }

  GroceryTemplateModel _fromSupabase(Map<String, dynamic> json) {
    return GroceryTemplateModel(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  GroceryTemplateItemModel _itemFromSupabase(Map<String, dynamic> json) {
    return GroceryTemplateItemModel(
      id: json['id'] as String,
      templateId: json['template_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      defaultQty: json['default_qty'] as int? ?? 1,
      notes: json['notes'] as String?,
      unit: json['unit'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }
}

