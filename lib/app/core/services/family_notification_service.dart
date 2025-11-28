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
        _logger.i('No other family members to notify');
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

      _logger.i('✅ Silent notification sent to ${memberIdsToNotify.length} family members for $dataType $action');
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
        _logger.i('No family members to notify');
        return;
      }

      // Send visible notification
      await _pushNotificationService.sendNotificationToUsers(
        userIds: memberIdsToNotify,
        title: title,
        body: body,
        data: data,
      );

      _logger.i('✅ Visible notification sent to ${memberIdsToNotify.length} family members: $title');
    } catch (e, stackTrace) {
      _logger.e('Error sending family notification: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - notification failure shouldn't block operations
    }
  }

  /// Notify when a task is assigned to a specific user
  Future<void> notifyTaskAssigned({
    required String familyId,
    required String assigneeId,
    required String taskId,
    required String taskTitle,
    String? createdById,
  }) async {
    await notifyFamilyMembers(
      familyId: familyId,
      title: 'New Task Assigned',
      body: '$taskTitle has been assigned to you',
      data: {
        'type': 'task',
        'task_id': taskId,
        'action': 'view_task',
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
    await notifyFamilyDataChanged(
      familyId: familyId,
      dataType: 'grocery_list',
      action: action,
      itemId: listId,
      itemTitle: listName,
      excludeUserId: excludeUserId,
    );
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
  Future<void> notifyCalendarEventChanged({
    required String familyId,
    required String action, // 'created', 'updated', 'deleted'
    String? eventId,
    String? eventTitle,
    String? excludeUserId,
  }) async {
    // For calendar events, send visible notification for new events
    if (action == 'created' && eventTitle != null) {
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
      // For updates/deletes, send silent notification
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

