import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background message
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();
  
  String? _fcmToken;
  bool _initialized = false;
  
  // Callback to refresh tasks when a task notification is received
  VoidCallback? _onTaskNotificationReceived;
  
  // Callback to refresh grocery lists when a grocery list notification is received
  VoidCallback? _onGroceryListNotificationReceived;
  
  // Callback to refresh events when an event notification is received
  VoidCallback? _onEventNotificationReceived;
  
  // Callback to refresh announcements when an announcement notification is received
  VoidCallback? _onAnnouncementNotificationReceived;
  
  // Callback to refresh templates when a template notification is received
  VoidCallback? _onTemplateNotificationReceived;
  
  /// Set callback to be called when a task notification is received
  /// This allows the app to refresh tasks when realtime stream isn't working
  void setTaskNotificationCallback(VoidCallback? callback) {
    _onTaskNotificationReceived = callback;
  }
  
  /// Set callback to be called when a grocery list notification is received
  /// This allows the app to refresh grocery lists when realtime stream isn't working
  void setGroceryListNotificationCallback(VoidCallback? callback) {
    _onGroceryListNotificationReceived = callback;
  }
  
  /// Set callback to be called when an event notification is received
  /// This allows the app to refresh events when realtime stream isn't working
  void setEventNotificationCallback(VoidCallback? callback) {
    _onEventNotificationReceived = callback;
  }
  
  /// Set callback to be called when an announcement notification is received
  /// This allows the app to refresh announcements when realtime stream isn't working
  void setAnnouncementNotificationCallback(VoidCallback? callback) {
    _onAnnouncementNotificationReceived = callback;
  }
  
  /// Set callback to be called when a template notification is received
  /// This allows the app to refresh templates when realtime stream isn't working
  void setTemplateNotificationCallback(VoidCallback? callback) {
    _onTemplateNotificationReceived = callback;
  }

  /// Initialize push notification service
  /// [requestPermissions] - If true, requests permission immediately. If false, only checks status.
  /// Set to false during app startup to avoid premature permission dialogs on iOS.
  Future<bool> initialize({bool requestPermissions = true}) async {
    if (_initialized) return true;

    try {
      // Check notification permission status
      var status = await Permission.notification.status;
      
      // Only request if explicitly requested and not already granted or permanently denied
      if (requestPermissions && status.isDenied) {
        final requestResult = await Permission.notification.request();
        
        // Re-check status after request (iOS sometimes takes a moment to update)
        if (!requestResult.isGranted) {
          // Wait a moment and re-check (iOS permission dialog might still be processing)
          await Future.delayed(const Duration(milliseconds: 500));
          status = await Permission.notification.status;
          
          if (!status.isGranted) {
            _logger.w('Notification permission not granted. User can enable it in settings later.');
            // Continue initialization anyway - user can grant permission later
          } else {
          }
        } else {
        }
      } else if (!requestPermissions) {
      } else if (status.isPermanentlyDenied) {
        _logger.w('Notification permission permanently denied. User needs to enable it in settings.');
        // Continue initialization anyway - token can still be saved
      } else if (status.isGranted) {
      } else {
        _logger.w('Notification permission status: $status (not granted)');
        // Continue initialization anyway
      }

      // Initialize local notifications for foreground messages
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      final initialized = await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Handle local notification tap if needed
        },
      );
      
      if (initialized == true) {
      } else {
        _logger.w('Local notifications initialization returned false');
      }

      // Create Android notification channels
      if (Platform.isAndroid) {
        await _createAndroidNotificationChannels();
      }

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Request FCM token
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToDatabase(newToken);
      });

      // Listen to auth state changes to save token when user logs in
      _supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn && _fcmToken != null) {
          _saveTokenToDatabase(_fcmToken!);
        } else if (event == AuthChangeEvent.signedOut) {
          _fcmToken = null;
        }
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from a notification
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      return true;
    } catch (e) {
      _logger.e('Push notification initialization error: $e');
      // Still mark as initialized to prevent retry loops
      _initialized = true;
      return false;
    }
  }

  /// Request notification permission (call this when user wants to enable notifications)
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.notification.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        _logger.w('Notification permission permanently denied. User must enable in settings.');
        return false;
      }
      
      final result = await Permission.notification.request();
      if (result.isGranted) {
        // If we have a token but it wasn't saved before, save it now
        if (_fcmToken != null) {
          await _saveTokenToDatabase(_fcmToken!);
        }
        return true;
      }
      
      _logger.w('Notification permission denied');
      return false;
    } catch (e) {
      _logger.e('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notification permission is granted
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.notification.status;
      return status.isGranted;
    } catch (e) {
      _logger.e('Error checking notification permission: $e');
      return false;
    }
  }

  /// Open app settings to allow user to enable notifications
  Future<void> openNotificationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      _logger.e('Error opening app settings: $e');
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _logger.w('No user logged in, cannot save FCM token');
        return;
      }

      // Try to insert first - if it fails due to duplicate, update instead
      // This handles race conditions where token might be inserted between check and insert
      try {
        await _supabase.from('user_fcm_tokens').insert({
          'user_id': userId,
          'token': token,
          'device_type': _getDeviceType(),
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (insertError) {
        // If insert fails due to duplicate key, update instead
        if (insertError is PostgrestException && 
            insertError.code == '23505' && 
            insertError.message.contains('user_fcm_tokens_token_key')) {
          await _supabase
              .from('user_fcm_tokens')
              .update({
                'user_id': userId,
                'device_type': _getDeviceType(),
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('token', token);
        } else {
          // Re-throw if it's a different error
          rethrow;
        }
      }
    } catch (e) {
      _logger.e('Error saving FCM token: $e');
      // Don't rethrow - token save failure shouldn't break the app
    }
  }

  /// Get device type (android/ios)
  String _getDeviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Create Android notification channels
  Future<void> _createAndroidNotificationChannels() async {
    if (!Platform.isAndroid) return;

    // Create push notifications channel
    const pushChannel = AndroidNotificationChannel(
      'push_notifications',
      'Push Notifications',
      description: 'Notifications from Supabase',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(pushChannel);

  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    
    // Extract notification data first
    final notification = message.notification;
    // For iOS, check both notification object and data payload
    // iOS APNs may put title/body in different places
    String title = notification?.title ?? '';
    String body = notification?.body ?? '';
    
    // If title/body are empty, check data payload (iOS sometimes puts them there)
    if (title.isEmpty) {
      title = message.data['title'] ?? '';
    }
    if (body.isEmpty) {
      body = message.data['body'] ?? '';
    }
    
    // Also check APNs-specific fields for iOS
    if (Platform.isIOS) {
      final apnsData = message.data;
      if (title.isEmpty && apnsData['aps'] != null) {
        try {
          final aps = apnsData['aps'] as Map<String, dynamic>?;
          final alert = aps?['alert'] as Map<String, dynamic>?;
          title = alert?['title']?.toString() ?? title;
          body = alert?['body']?.toString() ?? body;
        } catch (e) {
          _logger.w('Could not parse APNs alert: $e');
        }
      }
    }
    
    final data = message.data;
    
    // Check if this is a silent notification (data-only, no UI)
    // Only treat as silent if explicitly marked AND no title/body
    final isSilent = data['silent'] == 'true' && title.isEmpty && body.isEmpty;
    
    // Get notification type
    final notificationType = data['type'] as String?;
    
    // CRITICAL: Process data refresh callbacks FIRST, regardless of permission status
    // Silent notifications should always trigger data refreshes, even without permission
    // This ensures real-time updates work even if user hasn't granted notification permission
    
    // Process all notification callbacks FIRST (regardless of permission)
    // This ensures data refreshes work even without notification permission
    bool callbackTriggered = false;
    
    if (notificationType == 'task') {
      if (_onTaskNotificationReceived != null) {
        _onTaskNotificationReceived!();
        callbackTriggered = true;
      } else {
        _logger.w('⚠️ Task notification received but callback is not registered. Page may not be mounted.');
      }
    } else if (notificationType == 'grocery_list' || notificationType == 'grocery_list_item') {
      if (_onGroceryListNotificationReceived != null) {
        _onGroceryListNotificationReceived!();
        callbackTriggered = true;
      } else {
        _logger.w('⚠️ Grocery notification received but callback is not registered. Page may not be mounted.');
      }
    } else if (notificationType == 'event' || notificationType == 'calendar_event') {
      if (_onEventNotificationReceived != null) {
        _onEventNotificationReceived!();
        callbackTriggered = true;
      } else {
        _logger.w('⚠️ Event notification received but callback is not registered. Page may not be mounted.');
      }
    } else if (notificationType == 'announcement') {
      if (_onAnnouncementNotificationReceived != null) {
        _onAnnouncementNotificationReceived!();
        callbackTriggered = true;
      } else {
        _logger.w('⚠️ Announcement notification received but callback is not registered. Page may not be mounted.');
      }
    } else if (notificationType == 'grocery_template' || notificationType == 'task_template') {
      if (_onTemplateNotificationReceived != null) {
        _onTemplateNotificationReceived!();
        callbackTriggered = true;
      } else {
        _logger.w('⚠️ Template notification received but callback is not registered. Page may not be mounted.');
      }
    }
    
    // For silent notifications, we've already processed the data refresh
    // No need to show UI notification, regardless of permission status
    if (isSilent) {
      if (callbackTriggered) {
      } else {
      }
      return;
    }
    
    // For visible notifications, check permission before showing UI
    // Only check permission for notifications that need to show UI
    
    // Check if this notification is for the current logged-in user (direct assignment)
    // Only prioritize push notifications when the user is directly assigned
    bool isDirectAssignment = false;
    final currentUserId = _supabase.auth.currentUser?.id;
    
    if (currentUserId != null) {
      // Check if this is a task assignment to the current user
      if (notificationType == 'task' && data['action'] == 'view_task' && data['task_id'] != null) {
        try {
          // Fetch the task to check if it's assigned to the current user
          final taskResponse = await _supabase
              .from('tasks')
              .select('assigned_to')
              .eq('id', data['task_id'] as String)
              .maybeSingle();
          
          if (taskResponse != null) {
            final assignedTo = taskResponse['assigned_to'] as String?;
            isDirectAssignment = assignedTo == currentUserId;
            if (isDirectAssignment) {
            }
          }
        } catch (e) {
          _logger.w('Could not verify task assignment: $e');
        }
      }
      
      // Check if this is an event where the current user is a participant
      if ((notificationType == 'event' || notificationType == 'calendar_event') && 
          data['event_id'] != null) {
        try {
          // Fetch the event to check if current user is a participant
          final eventResponse = await _supabase
              .from('calendar_events')
              .select('participants')
              .eq('id', data['event_id'] as String)
              .maybeSingle();
          
          if (eventResponse != null) {
            final participants = (eventResponse['participants'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ?? [];
            isDirectAssignment = participants.contains(currentUserId);
            if (isDirectAssignment) {
            }
          }
        } catch (e) {
          _logger.w('Could not verify event participation: $e');
        }
      }
    } else {
      _logger.w('⚠️ No current user found - cannot verify direct assignment');
    }
    
    bool hasPermission = false;
    final permissionStatus = await Permission.notification.status;
    hasPermission = permissionStatus.isGranted;
    
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {
      // On iOS, re-check permission status after a brief delay
      // iOS sometimes takes a moment to update permission status after user grants it
      if (!hasPermission) {
        await Future.delayed(const Duration(milliseconds: 300));
        final recheckStatus = await Permission.notification.status;
        hasPermission = recheckStatus.isGranted;
        if (hasPermission) {
      }
      }
    }
    
    // For direct assignments (task/event assigned to current user), request permission if not granted
    // This ensures push notifications are prioritized for direct assignments
    if (isDirectAssignment && !hasPermission && !permissionStatus.isPermanentlyDenied) {
      final requestResult = await Permission.notification.request();
      if (requestResult.isGranted) {
        hasPermission = true;
      } else {
        _logger.w('⚠️ Permission not granted after request for direct assignment');
      }
    }
    
    // If still no permission and not permanently denied, try to show anyway (some platforms allow it)
    // For direct assignments, we want to ensure the user is notified
    if (!hasPermission && !permissionStatus.isPermanentlyDenied) {
      if (isDirectAssignment) {
        _logger.w('⚠️ Direct assignment notification - permission not granted, but attempting to show anyway');
        // Continue to try showing - some platforms may still allow it
      } else {
        _logger.w('⚠️ Notification permission not granted. Data refresh was already processed, but UI notification cannot be shown.');
        _logger.w('💡 User can enable notifications in app settings. Silent updates will continue to work.');
        return;
      }
    } else if (permissionStatus.isPermanentlyDenied) {
      if (isDirectAssignment) {
        _logger.w('⚠️ Direct assignment notification - permission permanently denied. Attempting to show anyway.');
        // For direct assignments, still try to show - user might have enabled it in settings
      } else {
        _logger.w('⚠️ Notification permission permanently denied. Data refresh was already processed.');
        _logger.w('💡 User must enable notifications in system settings to see UI notifications.');
        return;
      }
    }
    
    if (hasPermission) {
    } else if (isDirectAssignment) {
    }
    
    try {
      final notificationId = message.messageId?.hashCode ?? 
                            DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: const AndroidNotificationDetails(
            'push_notifications',
            'Push Notifications',
            channelDescription: 'Notifications from Supabase',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
      
    } catch (e, stackTrace) {
      _logger.e('❌ Error showing local notification: $e', error: e, stackTrace: stackTrace);
      _logger.e('Error details - title: "$title", body: "$body"');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    // Handle navigation based on message data
    final data = message.data;
    final notificationType = data['type'] as String?;
    if (notificationType == 'task') {
      // Trigger callback to refresh tasks when notification is tapped
      // This ensures tasks are refreshed when user opens app from notification
      if (_onTaskNotificationReceived != null) {
        _onTaskNotificationReceived!();
      }
      // Navigate to task detail page
      // You can use a navigation service or router here
    } else if (notificationType == 'grocery_list' || notificationType == 'grocery_list_item') {
      // Trigger callback to refresh grocery lists when notification is tapped
      if (_onGroceryListNotificationReceived != null) {
        _onGroceryListNotificationReceived!();
      }
      // Navigate to grocery list page if item_id is provided
      final itemId = data['item_id'] as String?;
      if (itemId != null) {
        // Navigate to specific grocery list
        // You can use a navigation service or router here
      }
    } else if (notificationType == 'event' || notificationType == 'calendar_event') {
      // Trigger callback to refresh events when notification is tapped
      if (_onEventNotificationReceived != null) {
        _onEventNotificationReceived!();
      }
      // Navigate to event detail page if item_id is provided
      final itemId = data['item_id'] as String?;
      if (itemId != null) {
        // Navigate to specific event
        // You can use a navigation service or router here
      }
    } else if (notificationType == 'announcement') {
      // Trigger callback to refresh announcements when notification is tapped
      if (_onAnnouncementNotificationReceived != null) {
        _onAnnouncementNotificationReceived!();
      }
      // Navigate to announcement detail page if announcement_id is provided
      final announcementId = data['announcement_id'] as String?;
      if (announcementId != null) {
        // Navigate to specific announcement
        // You can use a navigation service or router here
      }
    } else if (notificationType == 'grocery_template' || notificationType == 'task_template') {
      // Trigger callback to refresh templates when notification is tapped
      if (_onTemplateNotificationReceived != null) {
        _onTemplateNotificationReceived!();
      }
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Send push notification to a user (via Supabase Edge Function)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Call Supabase Edge Function to send notification
      final response = await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      
      // Log the response to see what happened
      
      // Check if notification was actually sent
      if (response.data != null) {
        final responseData = response.data as Map<String, dynamic>?;
        final sent = responseData?['sent'] as int? ?? 0;
        final failed = responseData?['failed'] as int? ?? 0;
        final message = responseData?['message'] as String? ?? '';
        
        if (sent == 0 && failed == 0) {
          _logger.w('No FCM tokens found for user: $userId. User may need to log in again or grant notification permissions.');
        } else if (sent > 0) {
        } else {
          _logger.w('Push notification failed for user: $userId (sent: $sent, failed: $failed, message: $message)');
        }
      } else {
      }
    } catch (e) {
      _logger.e('Error sending push notification: $e');
      rethrow;
    }
  }

  /// Send push notification to multiple users
  Future<void> sendNotificationToUsers({
    required List<String> userIds,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'user_ids': userIds,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
    } catch (e) {
      _logger.e('Error sending push notifications: $e');
      rethrow;
    }
  }

  /// Refresh and save FCM token (call this after login)
  Future<void> refreshToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        await _saveTokenToDatabase(_fcmToken!);
      } else {
        _logger.w('Failed to get FCM token');
      }
    } catch (e) {
      _logger.e('Error refreshing FCM token: $e');
    }
  }

  /// Check if user has FCM token in database
  Future<bool> hasTokenInDatabase() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _supabase
          .from('user_fcm_tokens')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      _logger.e('Error checking FCM token: $e');
      return false;
    }
  }

  /// Delete FCM token when user logs out
  Future<void> deleteToken() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null && _fcmToken != null) {
        await _supabase
            .from('user_fcm_tokens')
            .delete()
            .eq('user_id', userId)
            .eq('token', _fcmToken!);
      }
      _fcmToken = null;
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }
}

