import 'package:logger/logger.dart';
import '../services/push_notification_service.dart';
import '../../data/repositories/family_repository.dart';

/// Centralized service for sending notifications to family members
/// when shared family data changes
class FamilyNotificationService {
  static final FamilyNotificationService _instance = FamilyNotificationService._internal();
  factory FamilyNotificationService() => _instance;
  FamilyNotificationService._internal();

  final Logger _logger = Logger();
  final FamilyRepository _familyRepo = FamilyRepository();
  final PushNotificationService _pushNotificationService = PushNotificationService();

  /// Send silent notification to all family members to trigger refresh
  /// This is used for general updates (create, update, delete)
  Future<void> notifyFamilyDataChanged({
    required String familyId,
    required String dataType, // 'task', 'grocery_list', 'calendar_event', etc.
    required String action, // 'created', 'updated', 'deleted'
    String? itemId,
    String? itemTitle,
    String? excludeUserId, // Don't notify the user who made the change
  }) async {
    try {
      final familyMembers = await _familyRepo.getFamilyMembers(familyId);
      final allMemberIds = familyMembers.map((m) => m.uid).toList();

      if (allMemberIds.isEmpty) {
        _logger.w('No family members found for family $familyId');
        return;
      }

      // Exclude the user who made the change
      final memberIdsToNotify = excludeUserId != null
          ? allMemberIds.where((id) => id != excludeUserId).toList()
          : allMemberIds;

      if (memberIdsToNotify.isEmpty) {
        return;
      }

      // Send silent notification (data-only) to trigger refresh
      await _pushNotificationService.sendNotificationToUsers(
        userIds: memberIdsToNotify,
        title: '', // Empty = silent notification
        body: '', // Empty = silent notification
        data: {
          'type': dataType,
          'action': action,
          if (itemId != null) 'item_id': itemId,
          if (itemTitle != null) 'item_title': itemTitle,
          'silent': 'true',
          'refresh': 'true', // Signal to refresh the data
        },
      );

    } catch (e, stackTrace) {
      _logger.e('Error sending family notification: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - notification failure shouldn't block operations
    }
  }

  /// Send visible notification to specific user(s) for important events
  /// This is used for assignments, important updates, etc.
  Future<void> notifyFamilyMembers({
    required String familyId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    List<String>? specificUserIds, // If provided, only notify these users
    String? excludeUserId, // Don't notify this user
  }) async {
    try {
      final familyMembers = await _familyRepo.getFamilyMembers(familyId);
      final allMemberIds = familyMembers.map((m) => m.uid).toList();

      if (allMemberIds.isEmpty) {
        _logger.w('No family members found for family $familyId');
        return;
      }

      // Determine which users to notify
      List<String> memberIdsToNotify;
      if (specificUserIds != null && specificUserIds.isNotEmpty) {
        // Only notify specific users
        memberIdsToNotify = specificUserIds
            .where((id) => allMemberIds.contains(id) && id != excludeUserId)
            .toList();
      } else {
        // Notify all family members except the one who made the change
        memberIdsToNotify = excludeUserId != null
            ? allMemberIds.where((id) => id != excludeUserId).toList()
            : allMemberIds;
      }

      if (memberIdsToNotify.isEmpty) {
        return;
      }

      // Send visible notification
      // Always include 'refresh: true' to ensure data refresh happens even if permission is denied
      final notificationData = Map<String, dynamic>.from(data);
      notificationData['refresh'] = 'true';
      
      await _pushNotificationService.sendNotificationToUsers(
        userIds: memberIdsToNotify,
        title: title,
        body: body,
        data: notificationData,
      );

    } catch (e, stackTrace) {
      _logger.e('Error sending family notification: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - notification failure shouldn't block operations
    }
  }

  /// Notify when a task is assigned to a specific user
  /// 
  /// **Priority**: Push notifications are prioritized ONLY when the notification is for
  /// the current logged-in user (direct assignment). The system verifies this by checking
  /// if the task's `assigned_to` field matches the current user ID.
  /// 
  /// If push notification permission is not granted on the recipient's device for a direct
  /// assignment, the system will automatically request permission and fall back to local
  /// notifications. This ensures direct assignments are always delivered, even if the user
  /// hasn't granted notification permissions yet.
  /// 
  /// For general family notifications (not direct assignments), standard permission rules apply.
  Future<void> notifyTaskAssigned({
    required String familyId,
    required String assigneeId,
    required String taskId,
    required String taskTitle,
    String? createdById,
  }) async {
    // Send push notification (prioritized method)
    // On recipient device, if permission not granted, it will be requested
    // and fall back to local notification if needed
    await notifyFamilyMembers(
      familyId: familyId,
      title: 'New Task Assigned',
      body: '$taskTitle has been assigned to you',
      data: {
        'type': 'task',
        'task_id': taskId,
        'action': 'view_task', // Marks this as a task assignment notification
      },
      specificUserIds: [assigneeId],
      excludeUserId: createdById,
    );
  }

  /// Notify when a grocery list is created or updated
  Future<void> notifyGroceryListChanged({
    required String familyId,
    required String action, // 'created', 'updated', 'deleted'
    String? listId,
    String? listName,
    String? excludeUserId,
  }) async {
    // For important actions (created, deleted), send visible notifications
    // For updates, send silent notification (data refresh only)
    if (action == 'created' || action == 'deleted') {
      final title = action == 'created' 
          ? 'New Shopping List'
          : 'Shopping List Deleted';
      final body = listName != null
          ? action == 'created'
              ? '$listName was created'
              : '$listName was deleted'
          : action == 'created'
              ? 'A new shopping list was created'
              : 'A shopping list was deleted';
      
      await notifyFamilyMembers(
        familyId: familyId,
        title: title,
        body: body,
        data: {
          'type': 'grocery_list',
          'action': action,
          if (listId != null) 'item_id': listId,
          if (listName != null) 'item_title': listName,
          'refresh': 'true',
        },
        excludeUserId: excludeUserId,
      );
    } else {
      // For updates, send silent notification (data refresh only)
      await notifyFamilyDataChanged(
        familyId: familyId,
        dataType: 'grocery_list',
        action: action,
        itemId: listId,
        itemTitle: listName,
        excludeUserId: excludeUserId,
      );
    }
  }

  /// Notify when a grocery list item is checked/unchecked
  Future<void> notifyGroceryListItemChanged({
    required String familyId,
    required String listId,
    required String itemName,
    required bool checked,
    String? excludeUserId,
  }) async {
    await notifyFamilyDataChanged(
      familyId: familyId,
      dataType: 'grocery_list_item',
      action: checked ? 'checked' : 'unchecked',
      itemId: listId,
      itemTitle: itemName,
      excludeUserId: excludeUserId,
    );
  }

  /// Notify when a calendar event is created or updated
  /// 
  /// **Direct Assignment**: If participants are provided, sends push notifications
  /// to participants (direct assignment). Otherwise, sends to all family members.
  /// 
  /// **Fallback**: If push notification permission is not granted, falls back to
  /// soft notifications (silent data refresh).
  Future<void> notifyCalendarEventChanged({
    required String familyId,
    required String action, // 'created', 'updated', 'deleted'
    String? eventId,
    String? eventTitle,
    String? excludeUserId,
    List<String>? participants, // Direct participants - will receive push notifications
  }) async {
    // If participants are provided and this is a creation/update, send push notifications to participants
    if (participants != null && participants.isNotEmpty && 
        (action == 'created' || action == 'updated') && eventTitle != null) {
      // Send push notification to participants (direct assignment)
      await notifyEventParticipants(
        familyId: familyId,
        participantIds: participants,
        eventId: eventId,
        eventTitle: eventTitle,
        action: action,
        excludeUserId: excludeUserId,
      );
      
      // Send silent notification to other family members
      final familyMembers = await _familyRepo.getFamilyMembers(familyId);
      final allMemberIds = familyMembers.map((m) => m.uid).toList();
      final otherMemberIds = allMemberIds
          .where((id) => !participants.contains(id) && id != excludeUserId)
          .toList();
      
      if (otherMemberIds.isNotEmpty) {
        await notifyFamilyDataChanged(
          familyId: familyId,
          dataType: 'calendar_event',
          action: action,
          itemId: eventId,
          itemTitle: eventTitle,
          excludeUserId: excludeUserId,
        );
      }
    } else if (action == 'created' && eventTitle != null) {
      // For new events without specific participants, send visible notification to all
      await notifyFamilyMembers(
        familyId: familyId,
        title: 'New Calendar Event',
        body: '$eventTitle has been added',
        data: {
          'type': 'calendar_event',
          'event_id': eventId,
          'action': 'view_event',
        },
        excludeUserId: excludeUserId,
      );
    } else {
      // For updates/deletes without participants, send silent notification
      await notifyFamilyDataChanged(
        familyId: familyId,
        dataType: 'calendar_event',
        action: action,
        itemId: eventId,
        itemTitle: eventTitle,
        excludeUserId: excludeUserId,
      );
    }
  }

  /// Notify event participants (direct assignment)
  /// Similar to task assignments, participants receive push notifications
  Future<void> notifyEventParticipants({
    required String familyId,
    required List<String> participantIds,
    required String? eventId,
    required String? eventTitle,
    required String action,
    String? excludeUserId,
  }) async {
    final title = action == 'created' 
        ? 'New Calendar Event'
        : 'Calendar Event Updated';
    final body = eventTitle != null
        ? action == 'created'
            ? '$eventTitle has been added'
            : '$eventTitle has been updated'
        : action == 'created'
            ? 'A new calendar event has been added'
            : 'A calendar event has been updated';
    
    await notifyFamilyMembers(
      familyId: familyId,
      title: title,
      body: body,
      data: {
        'type': 'calendar_event',
        'event_id': eventId,
        'action': 'view_event', // Marks this as a direct participant notification
      },
      specificUserIds: participantIds,
      excludeUserId: excludeUserId,
    );
  }

  /// Notify when a grocery template is created or updated
  Future<void> notifyGroceryTemplateChanged({
    required String familyId,
    required String action, // 'created', 'updated', 'deleted'
    String? templateId,
    String? templateName,
    String? excludeUserId,
  }) async {
    await notifyFamilyDataChanged(
      familyId: familyId,
      dataType: 'grocery_template',
      action: action,
      itemId: templateId,
      itemTitle: templateName,
      excludeUserId: excludeUserId,
    );
  }

  /// Notify when a task template is created or updated
  Future<void> notifyTaskTemplateChanged({
    required String familyId,
    required String action, // 'created', 'updated', 'deleted'
    String? templateId,
    String? templateName,
    String? excludeUserId,
  }) async {
    await notifyFamilyDataChanged(
      familyId: familyId,
      dataType: 'task_template',
      action: action,
      itemId: templateId,
      itemTitle: templateName,
      excludeUserId: excludeUserId,
    );
  }

  /// Notify when an announcement is created
  Future<void> notifyAnnouncementCreated({
    required String familyId,
    required String announcementId,
    required String title,
    String? excludeUserId,
  }) async {
    await notifyFamilyMembers(
      familyId: familyId,
      title: 'New Announcement',
      body: title,
      data: {
        'type': 'announcement',
        'announcement_id': announcementId,
        'action': 'view_announcement',
      },
      excludeUserId: excludeUserId,
    );
  }

  /// Notify when points are awarded (for achievements, milestones, etc.)
  Future<void> notifyPointsAwarded({
    required String familyId,
    required String userId,
    required int points,
    String? reason,
    String? excludeUserId,
  }) async {
    // Only notify if it's a significant amount or achievement
    if (points >= 50 || reason == 'achievement_unlocked') {
      await notifyFamilyMembers(
        familyId: familyId,
        title: 'Points Awarded',
        body: '${points} points awarded${reason != null ? " for $reason" : ""}',
        data: {
          'type': 'points',
          'user_id': userId,
          'points': points.toString(),
          'reason': reason ?? '',
          'action': 'view_profile',
        },
        specificUserIds: [userId],
        excludeUserId: excludeUserId,
      );
    }
  }
}

