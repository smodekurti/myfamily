import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Logger _logger = Logger();
  bool _initialized = false;

  /// Initialize notification service
  /// [requestPermissions] - If true, requests permission immediately. If false, only checks status.
  /// Set to false during app startup to avoid premature permission dialogs on iOS.
  Future<bool> initialize({bool requestPermissions = true}) async {
    if (_initialized) return true;

    try {
      // Check current permission status first
      var status = await Permission.notification.status;
      _logger.i('Notification permission status: $status');
      
      // Only request permission if explicitly requested and not already granted
      if (requestPermissions && !status.isGranted && !status.isPermanentlyDenied) {
        _logger.i('Requesting notification permission...');
        status = await Permission.notification.request();
        _logger.i('Permission request result: $status');
        
        // Re-check after a brief delay (iOS sometimes takes a moment)
        if (!status.isGranted) {
          await Future.delayed(const Duration(milliseconds: 500));
          status = await Permission.notification.status;
          _logger.i('Re-checked permission status: $status');
        }
      } else if (!requestPermissions) {
        _logger.i('Skipping permission request (deferred until needed)');
      }
      
      if (!status.isGranted) {
        _logger.w('Notification permission not granted (will request when needed)');
        // Don't return false - we can still initialize the service
        // Permission will be requested when user actually schedules a notification
      } else {
      _logger.i('✅ Notification permission granted');
      }

      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _initialized = true;
        _logger.i('Notification service initialized');
        return true;
      }

      return false;
    } catch (e) {
      _logger.e('Notification initialization error: $e');
      return false;
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    // Handle navigation based on payload if needed
  }

  /// Schedule a notification for a specific date/time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Initialize without requesting permissions (permissions should be requested separately)
    if (!_initialized) {
      final initialized = await initialize(requestPermissions: false);
      if (!initialized) {
        _logger.w('Notification service not initialized, cannot schedule notification');
        return;
      }
    }

    // Check if we have permission before trying to schedule
    final hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      _logger.w('Notification permission not granted, cannot schedule notification');
      return;
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_reminders',
            'Task Reminders',
            channelDescription: 'Notifications for task due dates and assignments',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _logger.i('Notification scheduled: $id at $scheduledDate');
    } catch (e, stackTrace) {
      _logger.e('Schedule notification error: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - notification scheduling failure shouldn't block task operations
    }
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    // Initialize without requesting permissions (permissions should be requested separately)
    if (!_initialized) {
      final initialized = await initialize(requestPermissions: false);
      if (!initialized) {
        _logger.w('Notification service not initialized, cannot show notification');
        return;
      }
    }

    // Check if we have permission before trying to show
    final hasPermission = await Permission.notification.isGranted;
    if (!hasPermission) {
      _logger.w('Notification permission not granted, cannot show notification');
      return;
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_notifications',
            'Task Notifications',
            channelDescription: 'Notifications for task assignments and updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
      );
      _logger.i('Notification shown: $id');
    } catch (e, stackTrace) {
      _logger.e('Show notification error: $e', error: e, stackTrace: stackTrace);
      // Don't rethrow - notification showing failure shouldn't block operations
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _logger.i('Notification cancelled: $id');
    } catch (e) {
      _logger.e('Cancel notification error: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.i('All notifications cancelled');
    } catch (e) {
      _logger.e('Cancel all notifications error: $e');
    }
  }

  /// Schedule task due date reminder
  Future<void> scheduleTaskDueReminder({
    required String taskId,
    required String taskTitle,
    required DateTime dueDate,
    int reminderMinutesBefore = 60, // Default: 1 hour before
  }) async {
    final reminderTime = dueDate.subtract(Duration(minutes: reminderMinutesBefore));
    
    // Only schedule if reminder time is in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _getTaskNotificationId(taskId),
        title: 'Task Due Soon',
        body: '$taskTitle is due in ${reminderMinutesBefore} minutes',
        scheduledDate: reminderTime,
        payload: 'task:$taskId',
      );
    }
  }

  /// Schedule event reminder
  Future<void> scheduleEventReminder({
    required String eventId,
    required String eventTitle,
    required DateTime startTime,
    int reminderMinutesBefore = 30, // Default: 30 minutes before
  }) async {
    final reminderTime = startTime.subtract(Duration(minutes: reminderMinutesBefore));
    
    // Only schedule if reminder time is in the future
    if (reminderTime.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: _getEventNotificationId(eventId),
        title: 'Event Starting Soon',
        body: '$eventTitle starts in ${reminderMinutesBefore} minutes',
        scheduledDate: reminderTime,
        payload: 'event:$eventId',
      );
    }
  }

  /// Show task assignment notification
  Future<void> notifyTaskAssigned({
    required String taskId,
    required String taskTitle,
    required String assigneeName,
  }) async {
    await showNotification(
      id: _getTaskNotificationId(taskId),
      title: 'New Task Assigned',
      body: '$taskTitle has been assigned to you',
      payload: 'task:$taskId',
    );
  }

  /// Cancel task-related notifications
  Future<void> cancelTaskNotifications(String taskId) async {
    await cancelNotification(_getTaskNotificationId(taskId));
  }

  /// Cancel event-related notifications
  Future<void> cancelEventNotifications(String eventId) async {
    await cancelNotification(_getEventNotificationId(eventId));
  }

  /// Generate unique notification ID from task ID
  int _getTaskNotificationId(String taskId) {
    return taskId.hashCode.abs() % 1000000;
  }

  /// Generate unique notification ID from event ID
  int _getEventNotificationId(String eventId) {
    return (eventId.hashCode.abs() % 1000000) + 1000000;
  }
}

