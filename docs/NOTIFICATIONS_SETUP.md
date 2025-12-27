# Notifications Setup Guide

## How Notifications Work

The MyFamily app uses **local notifications** (not push notifications) via `flutter_local_notifications`. This means notifications are scheduled and displayed by the device itself, without requiring a server or Firebase Cloud Messaging.

### Notification Types

1. **Task Assignment Notifications** - Immediate notification when a task is assigned to you
2. **Task Due Date Reminders** - Scheduled 1 hour before task due date
3. **Event Reminders** - Scheduled 30 minutes before event start time

### How It Works

1. **Automatic Initialization**: The notification service is initialized when the app starts (in `main.dart`)
2. **Permission Request**: On first launch, the app automatically requests notification permissions
3. **Automatic Scheduling**: 
   - When you create a task with a due date → reminder is automatically scheduled
   - When you assign a task to someone → they get an immediate notification
   - When you create an event → reminder is automatically scheduled
4. **Automatic Cleanup**: When tasks/events are completed or deleted, their notifications are automatically cancelled

---

## Required Configurations

### ✅ Already Configured (No Action Needed)

1. **Android**: 
   - Notification channels are created automatically by the plugin
   - No additional AndroidManifest.xml changes needed

2. **iOS**: 
   - Permission requests are handled automatically
   - No additional Info.plist changes needed (for iOS 10+)

3. **Code**: 
   - Notification service is initialized in `main.dart`
   - Integrated into task and calendar repositories

---

## Optional: iOS Notification Permissions (iOS 10+)

For iOS 10 and above, permissions are requested automatically. However, if you want to customize the permission request message, you can add this to `ios/Runner/Info.plist`:

```xml
<key>NSUserNotificationsUsageDescription</key>
<string>We need permission to send you reminders about tasks and events.</string>
```

**Note**: This is optional - the app will work without it, but the permission dialog won't show a custom message.

---

## Testing Notifications

### Test Task Assignment Notification

1. Create a new task
2. Assign it to a different family member
3. They should receive an immediate notification: "New Task Assigned - [Task Title] has been assigned to you"

### Test Task Due Date Reminder

1. Create a task with a due date in the future (at least 1 hour away)
2. The reminder will be scheduled for 1 hour before the due date
3. When the reminder time arrives, you'll see: "Task Due Soon - [Task Title] is due in 60 minutes"

### Test Event Reminder

1. Create a calendar event with a start time in the future (at least 30 minutes away)
2. The reminder will be scheduled for 30 minutes before the event
3. When the reminder time arrives, you'll see: "Event Starting Soon - [Event Title] starts in 30 minutes"

---

## Troubleshooting

### Notifications Not Showing

1. **Check Permissions**: 
   - Go to device Settings → Apps → MyFamily → Notifications
   - Ensure notifications are enabled

2. **Check Device Settings**:
   - Android: Ensure "Do Not Disturb" mode is not blocking notifications
   - iOS: Check Notification Center settings

3. **Check Logs**: 
   - Look for "Notification service initialized" in the app logs
   - Check for any error messages related to notifications

### Notifications Not Scheduled

- Ensure the task/event date is in the future
- For task reminders: due date must be at least 1 hour in the future
- For event reminders: start time must be at least 30 minutes in the future

### Notifications Not Cancelled

- When you complete a task, its reminder should be automatically cancelled
- When you delete an event, its reminder should be automatically cancelled
- If notifications persist, you can manually cancel all notifications (this would require adding a UI button)

---

## Technical Details

### Notification IDs

- Task notifications use: `taskId.hashCode % 1000000`
- Event notifications use: `(eventId.hashCode % 1000000) + 1000000`

This ensures unique IDs for each notification.

### Notification Channels (Android)

Two channels are created automatically:
- **Task Reminders** (`task_reminders`) - For scheduled due date reminders
- **Task Notifications** (`task_notifications`) - For immediate assignment notifications

Users can customize notification settings per channel in Android Settings.

### Timezone Handling

The notification service uses the `timezone` package to handle timezone conversions correctly, ensuring reminders fire at the correct local time.

---

## Future Enhancements (Not Implemented)

- Customizable reminder times (currently fixed: 1 hour for tasks, 30 minutes for events)
- Notification preferences in Settings page
- Push notifications via FCM (would require Firebase setup)
- Notification history/log

---

## Summary

**Good News**: The notification system is **fully configured and ready to use**! 

- ✅ No additional setup required
- ✅ Permissions are requested automatically
- ✅ Notifications are scheduled automatically
- ✅ Works on both Android and iOS

Just run the app and notifications will work automatically when you create tasks with due dates or assign tasks to family members.



