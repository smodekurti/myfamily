import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/announcement_model.dart';
import '../../core/services/family_notification_service.dart';
import '../../core/services/role_permission_service.dart';

class AnnouncementRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final RolePermissionService _roleService = RolePermissionService();

  /// Create a new announcement
  Future<AnnouncementModel> createAnnouncement({
    required String familyId,
    required String title,
    required String message,
    required String createdBy,
  }) async {
    try {
      // Check permission to create announcements
      final canCreate = await _roleService.canPerformAction(
        userId: createdBy,
        familyId: familyId,
        action: 'create_announcement',
      );
      
      if (!canCreate) {
        throw Exception('You do not have permission to create announcements');
      }
      
      final announcementData = {
        'family_id': familyId,
        'title': title,
        'message': message,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
        'read_by': [],
      };

      final response = await _supabase
          .from('announcements')
          .insert(announcementData)
          .select()
          .single();

      final createdAnnouncement = AnnouncementModelHelpers.fromSupabase(response);
      _logger.i('Announcement created: ${createdAnnouncement.id}');

      // Notify family members
      try {
        await FamilyNotificationService().notifyAnnouncementCreated(
          familyId: familyId,
          announcementId: createdAnnouncement.id,
          title: title,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send announcement notification: $e');
      }

      return createdAnnouncement;
    } catch (e) {
      _logger.e('Create announcement error: $e');
      rethrow;
    }
  }

  /// Get all announcements for a family
  /// Children can now view and create announcements (permissions updated)
  Stream<List<AnnouncementModel>> streamFamilyAnnouncements(String familyId, {String? userId}) async* {
    try {
      yield* _supabase
          .from('announcements')
          .stream(primaryKey: ['id'])
          .eq('family_id', familyId)
          .order('created_at', ascending: false)
          .map((data) => (data as List)
              .map((json) => AnnouncementModelHelpers.fromSupabase(json as Map<String, dynamic>))
              .toList());
    } catch (e, stackTrace) {
      _logger.e('Error creating stream for announcements: $e', error: e, stackTrace: stackTrace);
      yield <AnnouncementModel>[];
    }
  }

  /// Mark announcement as read
  Future<void> markAsRead(String announcementId, String userId) async {
    try {
      // Get current read_by list
      final current = await _supabase
          .from('announcements')
          .select('read_by')
          .eq('id', announcementId)
          .single();

      final readBy = (current['read_by'] as List<dynamic>?)?.cast<String>() ?? [];
      
      if (!readBy.contains(userId)) {
        readBy.add(userId);
        
        await _supabase
            .from('announcements')
            .update({'read_by': readBy})
            .eq('id', announcementId);

        _logger.i('Announcement marked as read: $announcementId');
      }
    } catch (e) {
      _logger.e('Mark as read error: $e');
      rethrow;
    }
  }

  /// Delete an announcement
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      // Get announcement info before deleting
      final announcement = await _supabase
          .from('announcements')
          .select('family_id, title, created_by')
          .eq('id', announcementId)
          .single();
      final familyId = announcement['family_id'] as String;
      final title = announcement['title'] as String;
      final createdBy = announcement['created_by'] as String;
      
      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Only creator can delete (announcements don't have separate delete permission)
      // But check if user has permission to create announcements (implies delete own)
      final canCreate = await _roleService.canPerformAction(
        userId: userId,
        familyId: familyId,
        action: 'create_announcement',
      );
      
      if (!canCreate || userId != createdBy) {
        throw Exception('You do not have permission to delete this announcement');
      }

      await _supabase
          .from('announcements')
          .delete()
          .eq('id', announcementId);

      _logger.i('Announcement deleted: $announcementId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyFamilyDataChanged(
          familyId: familyId,
          dataType: 'announcement',
          action: 'deleted',
          itemId: announcementId,
          itemTitle: title,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send announcement delete notification: $e');
      }
    } catch (e) {
      _logger.e('Delete announcement error: $e');
      rethrow;
    }
  }

  /// Update an announcement
  Future<AnnouncementModel> updateAnnouncement({
    required String announcementId,
    String? title,
    String? message,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (message != null) updateData['message'] = message;

      final response = await _supabase
          .from('announcements')
          .update(updateData)
          .eq('id', announcementId)
          .select()
          .single();

      final updatedAnnouncement = AnnouncementModelHelpers.fromSupabase(response);
      _logger.i('Announcement updated: $announcementId');

      // Notify family members
      try {
        await FamilyNotificationService().notifyFamilyDataChanged(
          familyId: updatedAnnouncement.familyId,
          dataType: 'announcement',
          action: 'updated',
          itemId: announcementId,
          itemTitle: title ?? updatedAnnouncement.title,
          excludeUserId: updatedAnnouncement.createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send announcement notification: $e');
      }

      return updatedAnnouncement;
    } catch (e) {
      _logger.e('Update announcement error: $e');
      rethrow;
    }
  }
}


