import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import '../models/announcement_model.dart';

class AnnouncementRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

  /// Create a new announcement
  Future<AnnouncementModel> createAnnouncement({
    required String familyId,
    required String title,
    required String message,
    required String createdBy,
  }) async {
    try {
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

      _logger.i('Announcement created: ${response['id']}');
      return AnnouncementModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Create announcement error: $e');
      rethrow;
    }
  }

  /// Get all announcements for a family
  Stream<List<AnnouncementModel>> streamFamilyAnnouncements(String familyId) {
    return _supabase
        .from('announcements')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('created_at', ascending: false)
        .map((data) => (data as List)
            .map((json) => AnnouncementModelHelpers.fromSupabase(json as Map<String, dynamic>))
            .toList());
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
      await _supabase
          .from('announcements')
          .delete()
          .eq('id', announcementId);

      _logger.i('Announcement deleted: $announcementId');
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

      _logger.i('Announcement updated: $announcementId');
      return AnnouncementModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Update announcement error: $e');
      rethrow;
    }
  }
}

