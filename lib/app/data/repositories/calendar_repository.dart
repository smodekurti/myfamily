import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/family_notification_service.dart';
import '../../core/services/role_permission_service.dart';

class CalendarRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  final RolePermissionService _roleService = RolePermissionService();

  /// Create a new event
  Future<EventModel> createEvent({
    required String familyId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    required String createdBy,
    String? color,
    List<String>? participants,
  }) async {
    try {
      // Check permission to create events
      final canCreate = await _roleService.canPerformAction(
        userId: createdBy,
        familyId: familyId,
        action: 'create_event',
      );
      
      if (!canCreate) {
        throw Exception('You do not have permission to create calendar events');
      }
      
      final eventData = <String, dynamic>{
        'family_id': familyId,
        'title': title,
        'description': description,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'location': location,
        'created_by': createdBy,
        'participants': participants ?? [],
      };
      
      // Only include color if it's not null
      if (color != null) {
        eventData['color'] = color;
      }
      
      final response = await _supabase
          .from('calendar_events')
          .insert(eventData)
          .select()
          .single();

      final createdEvent = EventModelHelpers.fromSupabase(response);

      // Schedule event reminder
      try {
        await NotificationService().scheduleEventReminder(
          eventId: createdEvent.id,
          eventTitle: title,
          startTime: startTime,
        );
      } catch (e) {
        _logger.w('Failed to schedule event reminder: $e');
      }

      // Notify family members
      // Pass participants for direct assignment (push notifications to participants)
      try {
        await FamilyNotificationService().notifyCalendarEventChanged(
          familyId: familyId,
          action: 'created',
          eventId: createdEvent.id,
          eventTitle: title,
          excludeUserId: createdBy,
          participants: participants, // Pass participants for direct assignment
        );
      } catch (e) {
        _logger.w('Failed to send calendar event notification: $e');
      }

      return createdEvent;
    } catch (e) {
      _logger.e('Create event error: $e');
      rethrow;
    }
  }

  /// Update an existing event
  Future<EventModel> updateEvent({
    required String eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? color,
    List<String>? participants,
  }) async {
    try {
      // Get event info first
      final eventResponse = await _supabase
          .from('calendar_events')
          .select('family_id, created_by')
          .eq('id', eventId)
          .single();
      final familyId = eventResponse['family_id'] as String;
      
      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Check permission to edit events
      final canEdit = await _roleService.canPerformAction(
        userId: userId,
        familyId: familyId,
        action: 'edit_event',
      );
      
      if (!canEdit) {
        throw Exception('You do not have permission to edit calendar events');
      }
      
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startTime != null) updateData['start_time'] = startTime.toIso8601String();
      if (endTime != null) updateData['end_time'] = endTime.toIso8601String();
      if (location != null) updateData['location'] = location;
      if (color != null) updateData['color'] = color;
      if (participants != null) updateData['participants'] = participants;

      final response = await _supabase
          .from('calendar_events')
          .update(updateData)
          .eq('id', eventId)
          .select()
          .single();

      final updatedEvent = EventModelHelpers.fromSupabase(response);

      // Update event reminder if start time changed
      if (startTime != null) {
        try {
          // Cancel old reminder
          await NotificationService().cancelEventNotifications(eventId);
          // Schedule new reminder
          await NotificationService().scheduleEventReminder(
            eventId: eventId,
            eventTitle: updatedEvent.title,
            startTime: startTime,
          );
        } catch (e) {
          _logger.w('Failed to update event reminder: $e');
        }
      }

      // Notify family members
      // Pass participants for direct assignment (push notifications to participants)
      try {
        await FamilyNotificationService().notifyCalendarEventChanged(
          familyId: updatedEvent.familyId,
          action: 'updated',
          eventId: eventId,
          eventTitle: updatedEvent.title,
          excludeUserId: updatedEvent.createdBy,
          participants: updatedEvent.participants.isNotEmpty 
              ? updatedEvent.participants 
              : null, // Pass participants for direct assignment
        );
      } catch (e) {
        _logger.w('Failed to send calendar event notification: $e');
      }

      return updatedEvent;
    } catch (e) {
      _logger.e('Update event error: $e');
      rethrow;
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      // Get event info before deleting
      final event = await _supabase
          .from('calendar_events')
          .select('family_id, title, created_by')
          .eq('id', eventId)
          .single();
      final familyId = event['family_id'] as String;
      final eventTitle = event['title'] as String;
      final createdBy = event['created_by'] as String;
      
      // Get current user
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Check permission to delete events
      final canDelete = await _roleService.canPerformAction(
        userId: userId,
        familyId: familyId,
        action: 'delete_event',
      );
      
      if (!canDelete) {
        throw Exception('You do not have permission to delete calendar events');
      }

      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);


      // Notify family members
      try {
        await FamilyNotificationService().notifyCalendarEventChanged(
          familyId: familyId,
          action: 'deleted',
          eventId: eventId,
          eventTitle: eventTitle,
          excludeUserId: createdBy,
        );
      } catch (e) {
        _logger.w('Failed to send calendar event delete notification: $e');
      }
    } catch (e) {
      _logger.e('Delete event error: $e');
      rethrow;
    }
  }

  /// Get events for a family
  Future<List<EventModel>> getFamilyEvents(String familyId) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('family_id', familyId)
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => EventModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get family events error: $e');
      rethrow;
    }
  }

  /// Get events for a specific date range
  Future<List<EventModel>> getEventsForDateRange(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final response = await _supabase
          .from('calendar_events')
          .select()
          .eq('family_id', familyId)
          .gte('start_time', start.toIso8601String())
          .lte('start_time', end.toIso8601String())
          .order('start_time', ascending: true);

      return (response as List)
          .map((json) => EventModelHelpers.fromSupabase(json))
          .toList();
    } catch (e) {
      _logger.e('Get events for date range error: $e');
      rethrow;
    }
  }

  /// Get events for a specific date
  Future<List<EventModel>> getEventsForDate(
    String familyId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(seconds: 1));

      return getEventsForDateRange(familyId, startOfDay, endOfDay);
    } catch (e) {
      _logger.e('Get events for date error: $e');
      rethrow;
    }
  }

  /// Stream events for a family
  /// Children can now view and edit events (permissions updated)
  Stream<List<EventModel>> streamFamilyEvents(String familyId, {String? userId}) async* {
    try {
      // Stream all family events for all roles
      yield* _supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('start_time', ascending: true)
        .map((data) => data
            .map((json) => EventModelHelpers.fromSupabase(json))
            .toList());
    } catch (e, stackTrace) {
      _logger.e('Error creating stream for family events: $e', error: e, stackTrace: stackTrace);
      yield <EventModel>[];
    }
  }
}

