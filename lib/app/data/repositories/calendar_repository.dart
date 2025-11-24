import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/event_model.dart';

class CalendarRepository {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();

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

      _logger.i('Event created: ${response['id']}');
      return EventModelHelpers.fromSupabase(response);
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

      _logger.i('Event updated: $eventId');
      return EventModelHelpers.fromSupabase(response);
    } catch (e) {
      _logger.e('Update event error: $e');
      rethrow;
    }
  }

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase
          .from('calendar_events')
          .delete()
          .eq('id', eventId);

      _logger.i('Event deleted: $eventId');
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
  Stream<List<EventModel>> streamFamilyEvents(String familyId) {
    return _supabase
        .from('calendar_events')
        .stream(primaryKey: ['id'])
        .eq('family_id', familyId)
        .order('start_time', ascending: true)
        .map((data) => data
            .map((json) => EventModelHelpers.fromSupabase(json))
            .toList());
  }
}

