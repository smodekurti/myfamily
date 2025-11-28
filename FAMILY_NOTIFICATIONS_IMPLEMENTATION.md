# Family Notifications Implementation

## Overview
This document describes the comprehensive notification system that sends notifications (soft or hard) to all family members when shared family data changes. This ensures all devices stay synchronized and users are informed of important updates.

## Architecture

### Centralized Service: `FamilyNotificationService`
Located at `lib/app/core/services/family_notification_service.dart`, this singleton service provides:

1. **Silent Notifications** (`notifyFamilyDataChanged`): Data-only notifications that trigger UI refreshes without showing visible alerts
2. **Visible Notifications** (`notifyFamilyMembers`): Full notifications with title and body for important events
3. **Specialized Methods**: Convenience methods for specific data types (tasks, grocery lists, calendar events, etc.)

### Notification Types

#### Silent Notifications (Soft)
- Used for: General updates (create, update, delete)
- Purpose: Trigger data refresh on all devices
- Format: Empty title/body with data payload containing `silent: 'true'` and `refresh: 'true'`

#### Visible Notifications (Hard)
- Used for: Important events (task assignments, new announcements, new calendar events)
- Purpose: Alert users to important changes
- Format: Full notification with title and body

## Covered Data Types

### 1. Tasks (`tasks` table)
- **Create**: Visible notification to assignee, silent to others
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members
- **Assignment**: Special visible notification when task is assigned/reassigned

### 2. Grocery Lists (`grocery_lists` table)
- **Create**: Silent notification to all family members
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members

### 3. Grocery List Items (`grocery_list_items` table)
- **Add Item**: Silent notification to all family members
- **Toggle Checked**: Silent notification to all family members
- **Update Item**: Silent notification to all family members
- **Delete Item**: Silent notification to all family members

### 4. Calendar Events (`calendar_events` table)
- **Create**: Visible notification to all family members (new event)
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members

### 5. Grocery Templates (`grocery_templates` table)
- **Create**: Silent notification to all family members
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members

### 6. Task Templates (`task_templates` table)
- **Create**: Silent notification to all family members
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members

### 7. Announcements (`announcements` table)
- **Create**: Visible notification to all family members (important)
- **Update**: Silent notification to all family members
- **Delete**: Silent notification to all family members

## Implementation Details

### Repository Integration
All repositories have been updated to call `FamilyNotificationService` methods after successful CRUD operations:

1. **TaskRepository**: 
   - `createTask()` → Notifies assignee + silent to others
   - `updateTask()` → Notifies on reassignment + silent to others
   - `deleteTask()` → Silent to all

2. **GroceryListRepository**:
   - `createStandaloneList()` / `createList()` → Silent to all
   - `updateListName()` → Silent to all
   - `deleteList()` → Silent to all
   - `addItem()` → Silent to all
   - `toggleItem()` → Silent to all
   - `deleteItem()` → Silent to all

3. **CalendarRepository**:
   - `createEvent()` → Visible to all
   - `updateEvent()` → Silent to all
   - `deleteEvent()` → Silent to all

4. **GroceryTemplateRepository**:
   - `createTemplate()` → Silent to all
   - `updateTemplate()` → Silent to all
   - `deleteTemplate()` → Silent to all

5. **TaskTemplateRepository**:
   - `createTemplate()` → Silent to all
   - `updateTemplate()` → Silent to all
   - `deleteTemplate()` → Silent to all

6. **AnnouncementRepository**:
   - `createAnnouncement()` → Visible to all
   - `updateAnnouncement()` → Silent to all
   - `deleteAnnouncement()` → Silent to all

### Notification Payload Structure

#### Silent Notification
```json
{
  "type": "task|grocery_list|calendar_event|...",
  "action": "created|updated|deleted",
  "item_id": "uuid",
  "item_title": "Item Name",
  "silent": "true",
  "refresh": "true"
}
```

#### Visible Notification
```json
{
  "type": "task|announcement|calendar_event",
  "item_id": "uuid",
  "action": "view_task|view_announcement|view_event"
}
```

### Error Handling
- All notification calls are wrapped in try-catch blocks
- Notification failures do not block the main operation
- Errors are logged but do not propagate
- This ensures data operations succeed even if notifications fail

### Excluding the Initiator
- All notification methods accept an `excludeUserId` parameter
- The user who made the change is excluded from notifications
- This prevents users from receiving notifications for their own actions

## Usage Example

```dart
// In a repository after creating a task
try {
  await FamilyNotificationService().notifyTaskAssigned(
    familyId: familyId,
    assigneeId: assignedTo,
    taskId: taskId,
    taskTitle: title,
    createdById: createdBy,
  );
  
  await FamilyNotificationService().notifyFamilyDataChanged(
    familyId: familyId,
    dataType: 'task',
    action: 'created',
    itemId: taskId,
    itemTitle: title,
    excludeUserId: createdBy,
  );
} catch (e) {
  _logger.w('Failed to send notifications: $e');
  // Don't fail the operation
}
```

## Benefits

1. **Real-time Synchronization**: All devices receive updates immediately
2. **User Awareness**: Important events trigger visible notifications
3. **Efficient Updates**: Silent notifications trigger refreshes without interrupting users
4. **Centralized Logic**: All notification logic in one place for easy maintenance
5. **Resilient**: Notification failures don't break core functionality
6. **Comprehensive Coverage**: All shared family data types are covered

## Future Enhancements

1. **User Preferences**: Allow users to configure which notifications they receive
2. **Notification Batching**: Group multiple updates into a single notification
3. **Priority Levels**: Different notification styles based on importance
4. **Notification History**: Track sent notifications for debugging
5. **Webhook Integration**: Support for external notification systems

## Testing

To test the notification system:

1. **Create a task** on Device A → Should appear on Device B
2. **Update a grocery list** on Device A → Should update on Device B
3. **Add a calendar event** on Device A → Should show notification on Device B
4. **Delete an item** on Device A → Should disappear on Device B

All changes should propagate in real-time across all devices in the same family.

