import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'app/core/config/supabase_config.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/router/app_router.dart';
import 'app/core/providers/providers.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/push_notification_service.dart';

void main() async {
  // Run app in a zone to intercept print() calls and filter Supabase INFO messages
  runZonedGuarded(
    () async {
      await _initializeApp();
    },
    (error, stack) {
      // Handle errors silently in production
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        // Filter out Supabase INFO messages
        if (line.contains('supabase.supabase_flutter: INFO:') ||
            line.contains('***** Supabase init completed *****')) {
          return; // Suppress Supabase INFO messages
        }
        // Print other messages normally
        parent.print(zone, line);
      },
    ),
  );
}

Future<void> _initializeApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // If Firebase is not configured, continue without it
    // Push notifications will fail gracefully
    debugPrint('Firebase init failed: $e');
  }

  // Initialize Supabase
  // Note: Supabase SDK INFO messages are from the SDK itself and cannot be suppressed
  // They use the standard Dart print() function which is controlled by Flutter's logging

  // Validate Supabase configuration
  if (!SupabaseConfig.isConfigured) {
    // In debug mode, we can continue but Supabase operations will fail
    // In production, you might want to show an error screen instead
  }

  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl.isNotEmpty
          ? SupabaseConfig.supabaseUrl
          : 'https://placeholder.supabase.co', // Placeholder to prevent immediate crash
      anonKey: SupabaseConfig.supabaseAnonKey.isNotEmpty
          ? SupabaseConfig.supabaseAnonKey
          : 'placeholder-key', // Placeholder to prevent immediate crash
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e) {
    // Continue without Supabase - the app will show errors when trying to use Supabase features
  }

  // Initialize services WITHOUT requesting permissions
  // Permissions will be requested when user actually needs the features
  // This prevents premature permission dialogs on iOS
  await NotificationService().initialize(requestPermissions: false);
  await PushNotificationService().initialize(requestPermissions: false);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MyFamilyApp()));
}

class MyFamilyApp extends ConsumerStatefulWidget {
  const MyFamilyApp({super.key});

  @override
  ConsumerState<MyFamilyApp> createState() => _MyFamilyAppState();
}

class _MyFamilyAppState extends ConsumerState<MyFamilyApp> {
  @override
  void initState() {
    super.initState();
    // Register global callbacks immediately to ensure they're always available
    _registerGlobalCallbacks();

    // Load theme preference from user profile after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemePreference();
      // Re-register callbacks after first frame to ensure they're set with proper ref context
      _registerGlobalCallbacks();
    });
  }

  void _loadThemePreference() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final userProfileAsync = ref.read(userProfileProvider(currentUser.id));
      userProfileAsync.whenData((profile) {
        if (profile != null && profile.themePreference != 'system') {
          final themeMode = profile.themePreference == 'light'
              ? ThemeMode.light
              : profile.themePreference == 'dark'
              ? ThemeMode.dark
              : ThemeMode.system;
          ref.read(themeModeProvider.notifier).state = themeMode;
        }
      });
    }
  }

  void _registerGlobalCallbacks() {
    // Services temporarily disabled for debugging
  }

  @override
  Widget build(BuildContext context) {
    // Re-register global callbacks whenever the family changes
    ref.listen(currentFamilyProvider, (previous, next) {
      if (next != null) {
        _registerGlobalCallbacks();
      }
    });

    return ScreenUtilInit(
      designSize: const Size(390, 844), // iPhone 12/13/14 dimensions
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Consumer(
          builder: (context, ref, child) {
            // Initialize theme and router
            final themeMode = ref.watch(themeModeProvider);
            final router = ref.watch(routerProvider);

            return MaterialApp.router(
              title: 'MyFamily',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              routerConfig: router,
              builder: (context, child) {
                // Return child directly to avoid Navigator key duplication issues
                return child!;
              },
            );
          },
        );
      },
    );
  }
}
