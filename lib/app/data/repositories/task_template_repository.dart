import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:logger/logger.dart';
import '../models/task_template_model.dart';
import '../../core/services/family_notification_service.dart';

class TaskTemplateRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  final Uuid _uuid = const Uuid();

  /// Check if a template name already exists for a family
  Future<bool> templateNameExists(String familyId, String name) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select('id')
          .eq('family_id', familyId)
          .eq('name', name.trim())
          .limit(1);
      
      return (response as List).isNotEmpty;
    } catch (e) {
      _logger.e('Check task template name error: $e');
      return false; // Return false on error to allow creation
    }
  }

  /// Create a task template
  Future<TaskTemplateModel> createTemplate({
    required String familyId,
    required String name,
    required String title,
    String? description,
    String? category,
    String? priority,
    int? points,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
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
        'id': _uuid.v4(),
        'family_id': familyId,
        'name': name.trim(),
        'title': title.trim(),
        'description': description?.trim(),
        'category': category,
        'priority': priority,
        'points': points,
        'recurrence_type': recurrenceType,
        'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
        'created_by': createdBy,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final response = await _supabase
          .from('task_templates')
          .insert(templateData)
          .select()
          .single();

      final createdTemplate = TaskTemplateModelHelpers.fromSupabase(response);

      // Notify family members
      try {
        await FamilyNotificationService().notifyTaskTemplateChanged(
          familyId: familyId,
          action: 'created',
          templateId: createdTemplate.id,
          templateName: name,
          excludeUserId: createdBy,
        );
      } catch (e) {      }

      return createdTemplate;
    } catch (e) {
      _logger.e('Create task template error: $e');
      rethrow;
    }
  }

  /// Get all templates for a family
  Future<List<TaskTemplateModel>> getTemplatesForFamily(String familyId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => TaskTemplateModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get task templates for family error: $e');
      rethrow;
    }
  }

  /// Get a template by ID
  Future<TaskTemplateModel?> getTemplate(String templateId) async {
    try {
      final response = await _supabase
          .from('task_templates')
          .select()
          .eq('id', templateId)
          .maybeSingle();

      if (response == null) return null;
      return TaskTemplateModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Get task template error: $e');
      rethrow;
    }
  }

  /// Update a task template
  Future<TaskTemplateModel> updateTemplate({
    required String templateId,
    String? name,
    String? title,
    String? description,
    String? category,
    String? priority,
    int? points,
    String? recurrenceType,
    DateTime? recurrenceEndDate,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name.trim();
      if (title != null) updates['title'] = title.trim();
      if (description != null) updates['description'] = description.trim();
      if (category != null) updates['category'] = category;
      if (priority != null) updates['priority'] = priority;
      if (points != null) updates['points'] = points;
      if (recurrenceType != null) updates['recurrence_type'] = recurrenceType;
      if (recurrenceEndDate != null) {
        updates['recurrence_end_date'] = recurrenceEndDate.toIso8601String();
      } else if (recurrenceType == null || recurrenceType == 'none') {
        updates['recurrence_end_date'] = null;
      }

      final response = await _supabase
          .from('task_templates')
          .update(updates)
          .eq('id', templateId)
          .select()
          .single();

      final updatedTemplate = TaskTemplateModelHelpers.fromSupabase(response);

      // Notify family members
      try {
        // Get family ID from template
        final template = await getTemplate(templateId);
        if (template != null) {
          await FamilyNotificationService().notifyTaskTemplateChanged(
            familyId: template.familyId,
            action: 'updated',
            templateId: templateId,
            templateName: name ?? template.name,
            excludeUserId: template.createdBy,
          );
        }
      } catch (e) {      }

      return updatedTemplate;
    } catch (e) {
      _logger.e('Update task template error: $e');
      rethrow;
    }
  }

  /// Delete a task template
  Future<void> deleteTemplate(String templateId) async {
    try {
      // Get template info before deleting
      final template = await getTemplate(templateId);
      final familyId = template?.familyId;
      final templateName = template?.name;
      final createdBy = template?.createdBy;

      await _supabase
          .from('task_templates')
          .delete()
          .eq('id', templateId);


      // Notify family members
      if (familyId != null) {
        try {
          await FamilyNotificationService().notifyTaskTemplateChanged(
            familyId: familyId,
            action: 'deleted',
            templateId: templateId,
            templateName: templateName,
            excludeUserId: createdBy,
          );
        } catch (e) {        }
      }
    } catch (e) {
      _logger.e('Delete task template error: $e');
      rethrow;
    }
  }
}

