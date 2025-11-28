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
  Logger().i('Background message received: ${message.messageId}');
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
  
  /// Set callback to be called when a task notification is received
  /// This allows the app to refresh tasks when realtime stream isn't working
  void setTaskNotificationCallback(VoidCallback? callback) {
    _onTaskNotificationReceived = callback;
  }

  /// Initialize push notification service
  /// [requestPermissions] - If true, requests permission immediately. If false, only checks status.
  /// Set to false during app startup to avoid premature permission dialogs on iOS.
  Future<bool> initialize({bool requestPermissions = true}) async {
    if (_initialized) return true;

    try {
      // Check notification permission status
      var status = await Permission.notification.status;
      _logger.i('Initial notification permission status: $status');
      
      // Only request if explicitly requested and not already granted or permanently denied
      if (requestPermissions && status.isDenied) {
        _logger.i('Requesting notification permission...');
        final requestResult = await Permission.notification.request();
        _logger.i('Permission request result: $requestResult');
        
        // Re-check status after request (iOS sometimes takes a moment to update)
        if (!requestResult.isGranted) {
          // Wait a moment and re-check (iOS permission dialog might still be processing)
          await Future.delayed(const Duration(milliseconds: 500));
          status = await Permission.notification.status;
          _logger.i('Re-checked permission status after request: $status');
          
          if (!status.isGranted) {
            _logger.w('Notification permission not granted. User can enable it in settings later.');
            // Continue initialization anyway - user can grant permission later
          } else {
            _logger.i('✅ Notification permission granted after re-check');
          }
        } else {
          _logger.i('✅ Notification permission granted');
        }
      } else if (!requestPermissions) {
        _logger.i('Skipping permission request (deferred until user enables notifications)');
      } else if (status.isPermanentlyDenied) {
        _logger.w('Notification permission permanently denied. User needs to enable it in settings.');
        // Continue initialization anyway - token can still be saved
      } else if (status.isGranted) {
        _logger.i('✅ Notification permission already granted');
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
          _logger.i('Local notification tapped: ${response.payload}');
          // Handle local notification tap if needed
        },
      );
      
      if (initialized == true) {
        _logger.i('Local notifications initialized successfully');
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
        _logger.i('FCM Token obtained: ${_fcmToken!.substring(0, 20)}...');
        await _saveTokenToDatabase(_fcmToken!);
      }

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _logger.i('FCM Token refreshed');
        _saveTokenToDatabase(newToken);
      });

      // Listen to auth state changes to save token when user logs in
      _supabase.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedIn && _fcmToken != null) {
          _logger.i('User signed in, saving FCM token');
          _saveTokenToDatabase(_fcmToken!);
        } else if (event == AuthChangeEvent.signedOut) {
          _logger.i('User signed out, clearing FCM token');
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
      _logger.i('Push notification service initialized');
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
        _logger.i('Notification permission already granted');
        return true;
      }
      
      if (status.isPermanentlyDenied) {
        _logger.w('Notification permission permanently denied. User must enable in settings.');
        return false;
      }
      
      final result = await Permission.notification.request();
      if (result.isGranted) {
        _logger.i('Notification permission granted');
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

      // Check if token already exists
      final existing = await _supabase
          .from('user_fcm_tokens')
          .select('id')
          .eq('user_id', userId)
          .eq('token', token)
          .maybeSingle();

      if (existing == null) {
        // Insert new token
        await _supabase.from('user_fcm_tokens').insert({
          'user_id': userId,
          'token': token,
          'device_type': _getDeviceType(),
          'created_at': DateTime.now().toIso8601String(),
        });
        _logger.i('FCM token saved to database');
      }
    } catch (e) {
      _logger.e('Error saving FCM token: $e');
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

    _logger.i('Android notification channels created');
  }

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Foreground message received: ${message.messageId}');
    _logger.i('Message data: ${message.data}');
    _logger.i('Message notification: ${message.notification?.title} - ${message.notification?.body}');
    
    // Check notification permissions before showing
    bool hasPermission = false;
    
    // Use permission_handler for both Android and iOS
    final permissionStatus = await Permission.notification.status;
    hasPermission = permissionStatus.isGranted;
    
    if (Platform.isAndroid) {
      _logger.i('Android notification permission status: $permissionStatus');
    } else if (Platform.isIOS) {
      _logger.i('iOS notification permission status: $permissionStatus');
    }
    
    // If permission is not granted, try requesting it
    // Note: On iOS, if permission was previously denied, this won't show a dialog
    if (!hasPermission) {
      final requestResult = await Permission.notification.request();
      hasPermission = requestResult.isGranted;
      
      if (Platform.isAndroid) {
        _logger.i('Android permission request result: $requestResult');
      } else if (Platform.isIOS) {
        _logger.i('iOS permission request result: $requestResult');
      }
    }
    
    if (!hasPermission) {
      _logger.w('Notification permission not granted, cannot show notification');
      return;
    }
    
    _logger.i('✅ Proceeding to show notification');
    
    // Show local notification for foreground messages
    // iOS doesn't show notifications automatically when app is in foreground
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'New Notification';
    final body = notification?.body ?? message.data['body'] ?? 'You have a new notification';
    final data = message.data;
    
    // Check if this is a silent notification (data-only, no UI)
    final isSilent = data['silent'] == 'true' || (title.isEmpty && body.isEmpty);
    
    // If this is a task notification, trigger callback to refresh tasks
    // This is a fallback when realtime stream isn't working
    if (data['type'] == 'task' && _onTaskNotificationReceived != null) {
      _logger.i('🔄 Task notification received, triggering task refresh callback');
      _onTaskNotificationReceived!();
      
      // For silent notifications, don't show UI notification - just refresh
      if (isSilent) {
        _logger.i('🔄 Silent task notification - skipping UI notification, refresh triggered');
        return;
      }
    }
    
    // For silent notifications, don't show notification UI
    if (isSilent) {
      _logger.i('🔄 Silent notification - skipping UI notification');
      return;
    }
    
    try {
      final notificationId = message.messageId?.hashCode ?? 
                            DateTime.now().millisecondsSinceEpoch.remainder(100000);
      
      _logger.i('Attempting to show notification: ID=$notificationId, title="$title", body="$body"');
      
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
      
      _logger.i('✅ Local notification show() completed: $title - $body');
    } catch (e, stackTrace) {
      _logger.e('❌ Error showing local notification: $e', error: e, stackTrace: stackTrace);
      _logger.e('Error details - title: "$title", body: "$body"');
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data
    final data = message.data;
    if (data['type'] == 'task') {
      // Trigger callback to refresh tasks when notification is tapped
      // This ensures tasks are refreshed when user opens app from notification
      if (_onTaskNotificationReceived != null) {
        _logger.i('🔄 Task notification tapped, triggering task refresh callback');
        _onTaskNotificationReceived!();
      }
      // Navigate to task detail page
      // You can use a navigation service or router here
    } else if (data['type'] == 'event') {
      // Navigate to event detail page
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
      _logger.i('Push notification response: $response');
      
      // Check if notification was actually sent
      if (response.data != null) {
        final responseData = response.data as Map<String, dynamic>?;
        final sent = responseData?['sent'] as int? ?? 0;
        final failed = responseData?['failed'] as int? ?? 0;
        final message = responseData?['message'] as String? ?? '';
        
        if (sent == 0 && failed == 0) {
          _logger.w('No FCM tokens found for user: $userId. User may need to log in again or grant notification permissions.');
        } else if (sent > 0) {
          _logger.i('Push notification sent to user: $userId (sent: $sent, failed: $failed)');
        } else {
          _logger.w('Push notification failed for user: $userId (sent: $sent, failed: $failed, message: $message)');
        }
      } else {
        _logger.i('Push notification sent to user: $userId (no response data)');
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
      _logger.i('Push notification sent to ${userIds.length} users');
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
        _logger.i('FCM Token refreshed: ${_fcmToken!.substring(0, 20)}...');
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
        _logger.i('FCM token deleted');
      }
      _fcmToken = null;
    } catch (e) {
      _logger.e('Error deleting FCM token: $e');
    }
  }
}

