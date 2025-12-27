# Notification Logic Summary

This document summarizes the consistent notification logic implemented across all entities in the MyFamily app.

## Core Principles

1. **Always retrieve from server when possible** - All repositories use Supabase real-time streams (`.stream()`) for automatic data synchronization
2. **Notify members when changes occur** - All CRUD operations trigger notifications to family members
3. **Use Visual Notifications (Push) when member is directly assigned** - Direct assignments (tasks, event participants) receive push notifications
4. **Fallback to Soft Notifications** - If push notification permission is denied/disabled, data refresh still occurs via silent notifications
5. **Use Soft Notifications for all other changes** - General updates use silent notifications to trigger data refresh

## Notification Types

### Silent Notifications (Soft)
- **Purpose**: Trigger data refresh without showing UI
- **Format**: Empty title/body with `silent: 'true'` and `refresh: 'true'` in data payload
- **Behavior**: Always processed FIRST, regardless of permission status
- **Used for**: General updates, deletes, non-assignment changes

### Visible Notifications (Push)
- **Purpose**: Alert users to important changes
- **Format**: Full notification with title and body, includes `refresh: 'true'` for data sync
- **Behavior**: Requires permission, but data refresh happens even if permission denied
- **Used for**: Direct assignments, important events (new announcements, new events)

## Entity-Specific Logic

### 1. Tasks (`tasks` table)

#### Create Task
- **Direct Assignment**: If `assignedTo != createdBy`
  - ✅ Push notification to assignee via `notifyTaskAssigned()`
  - ✅ Silent notification to all other family members
- **Self-Assignment**: If `assignedTo == createdBy`
  - ✅ Silent notification to all other family members

#### Update Task
- **Assignee Changed**: If assignee changed
  - ✅ Push notification to new assignee via `notifyTaskAssigned()`
  - ✅ Silent notification to all family members
- **Other Updates**: If assignee unchanged
  - ✅ Silent notification to all family members

#### Delete Task
- ✅ Silent notification to all family members

**Real-time**: ✅ Uses `streamTasksForFamily()` with Supabase streams

---

### 2. Calendar Events (`calendar_events` table)

#### Create Event
- **With Participants**: If `participants` list is provided and not empty
  - ✅ Push notification to participants via `notifyEventParticipants()`
  - ✅ Silent notification to other family members
- **Without Participants**: If no participants specified
  - ✅ Visible notification to all family members (new event is important)

#### Update Event
- **With Participants**: If `participants` list is provided and not empty
  - ✅ Push notification to participants via `notifyEventParticipants()`
  - ✅ Silent notification to other family members
- **Without Participants**: If no participants specified
  - ✅ Silent notification to all family members

#### Delete Event
- ✅ Silent notification to all family members

**Real-time**: ✅ Uses `streamFamilyEvents()` with Supabase streams

---

### 3. Grocery Lists (`grocery_lists` table)

#### Create List
- ✅ Visible notification to all family members (important event)

#### Update List
- ✅ Silent notification to all family members

#### Delete List
- ✅ Visible notification to all family members (important event)

**Real-time**: ✅ Uses `streamStandaloneListsForFamily()` and `streamAllListsForFamily()` with Supabase streams

---

### 4. Announcements (`announcements` table)

#### Create Announcement
- ✅ Visible notification to all family members (important event)

#### Update Announcement
- ✅ Silent notification to all family members

#### Delete Announcement
- ✅ Silent notification to all family members

**Real-time**: ✅ Uses `streamFamilyAnnouncements()` with Supabase streams

---

### 5. Grocery Templates (`grocery_templates` table)

#### Create/Update/Delete Template
- ✅ Silent notification to all family members

**Real-time**: ✅ Uses `streamGroceryTemplates()` with Supabase streams

---

### 6. Task Templates (`task_templates` table)

#### Create/Update/Delete Template
- ✅ Silent notification to all family members

**Real-time**: ✅ Uses `streamTaskTemplates()` with Supabase streams

---

## Fallback Mechanism

### How Fallback Works

1. **Data Refresh Always Happens First**
   - In `push_notification_service.dart`, `_handleForegroundMessage()` processes data refresh callbacks BEFORE checking permissions
   - This ensures silent updates work even if permission is denied

2. **Visible Notifications Include Refresh Flag**
   - All visible notifications include `refresh: 'true'` in the data payload
   - This ensures data refresh happens even if UI notification cannot be shown

3. **Permission Handling**
   - For direct assignments: Permission is requested if not granted
   - For general notifications: If permission denied, data refresh still occurs (soft notification)
   - Silent notifications: Always processed, no permission check needed

### Flow Diagram

```
Notification Received
    ↓
Process Data Refresh Callbacks (ALWAYS - regardless of permission)
    ↓
Is Silent Notification?
    ├─ YES → Return (data refresh done, no UI needed)
    └─ NO → Check Permission
            ├─ Granted → Show UI Notification
            └─ Denied → Return (data refresh already done)
```

## Implementation Details

### FamilyNotificationService Methods

- `notifyFamilyDataChanged()` - Silent notifications (soft)
- `notifyFamilyMembers()` - Visible notifications (push)
- `notifyTaskAssigned()` - Direct task assignment (push to assignee)
- `notifyEventParticipants()` - Direct event assignment (push to participants)
- `notifyCalendarEventChanged()` - Calendar event notifications (handles participants)
- `notifyGroceryListChanged()` - Grocery list notifications
- `notifyAnnouncementCreated()` - Announcement notifications
- `notifyGroceryTemplateChanged()` - Template notifications
- `notifyTaskTemplateChanged()` - Task template notifications

### Push Notification Service

- `_handleForegroundMessage()` - Processes notifications when app is open
  - Processes data refresh callbacks FIRST
  - Checks for direct assignments (tasks, events)
  - Handles permission requests for direct assignments
  - Falls back gracefully when permission denied

### Repository Pattern

All repositories follow this pattern:
1. Check permissions (role-based access control)
2. Perform CRUD operation
3. Send notification via `FamilyNotificationService`
4. Use Supabase streams for real-time updates

## Verification Checklist

- ✅ All entities use Supabase streams for real-time updates
- ✅ All CRUD operations trigger notifications
- ✅ Direct assignments (tasks, events) use push notifications
- ✅ General updates use silent notifications
- ✅ Data refresh happens even if permission denied
- ✅ Fallback mechanism works correctly
- ✅ All visible notifications include `refresh: 'true'`

## Testing

To verify the notification logic:

1. **Direct Assignment (Task)**
   - Create task assigned to another user
   - Verify: Assignee receives push notification, others receive silent notification

2. **Direct Assignment (Event)**
   - Create event with participants
   - Verify: Participants receive push notification, others receive silent notification

3. **General Update**
   - Update any entity (task, event, list, etc.)
   - Verify: All family members receive silent notification (data refresh)

4. **Permission Denied**
   - Disable notification permission
   - Create/update any entity
   - Verify: Data still refreshes (silent notification works)

5. **Real-time Updates**
   - Open app on two devices
   - Create/update entity on one device
   - Verify: Other device updates automatically via Supabase streams

