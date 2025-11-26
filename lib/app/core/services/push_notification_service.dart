import 'dart:io';
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

  /// Initialize push notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Request notification permission
      final status = await Permission.notification.request();
      if (!status.isGranted) {
        _logger.w('Notification permission not granted');
        return false;
      }

      // Initialize local notifications for foreground messages
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
      );

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
      return false;
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

  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.i('Foreground message received: ${message.messageId}');
    
    // Show local notification for foreground messages
    final notification = message.notification;
    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title ?? 'New Notification',
        notification.body ?? '',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'push_notifications',
            'Push Notifications',
            channelDescription: 'Notifications from Supabase',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    _logger.i('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data
    final data = message.data;
    if (data['type'] == 'task') {
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
      await _supabase.functions.invoke(
        'send-push-notification',
        body: {
          'user_id': userId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );
      _logger.i('Push notification sent to user: $userId');
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

