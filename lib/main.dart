import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/core/config/supabase_config.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/router/app_router.dart';
import 'app/core/providers/providers.dart';
import 'app/common/responsive/responsive_helper.dart';
import 'app/core/services/notification_service.dart';
import 'app/core/services/push_notification_service.dart';
import 'app/features/groceries/presentation/pages/grocery_list_page.dart';

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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase is not configured, continue without it
    // Push notifications will fail gracefully
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

  // Initialize push notification service without requesting permissions
  // Permission will be requested when user enables notifications in settings
  await PushNotificationService().initialize(requestPermissions: false);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  // Note: System UI colors are set dynamically based on theme in the app
  // This is just an initial setting and will be overridden by theme

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
    // Register global callbacks that work from any page
    // This ensures data refreshes even when user is not on the specific page
    // Individual pages will register their own callbacks for more specific refreshes

    // Grocery list callback
    PushNotificationService().setGroceryListNotificationCallback(() {
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null && mounted) {
        ref.invalidate(allGroceryListsProvider(currentFamily.id));
        ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
      }
    });

    // Task callback
    PushNotificationService().setTaskNotificationCallback(() {
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null && mounted) {
        ref.invalidate(familyTasksProvider(currentFamily.id));
        ref.invalidate(tasksDueTodayProvider(currentFamily.id));
        ref.invalidate(taskStatsProvider(currentFamily.id));
      }
    });

    // Event callback
    PushNotificationService().setEventNotificationCallback(() {
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null && mounted) {
        ref.invalidate(familyEventsProvider(currentFamily.id));
      }
    });

    // Announcement callback
    PushNotificationService().setAnnouncementNotificationCallback(() {
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null && mounted) {
        ref.invalidate(familyAnnouncementsProvider(currentFamily.id));
      }
    });

    // Template callback (for both grocery and task templates)
    PushNotificationService().setTemplateNotificationCallback(() {
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily != null && mounted) {
        // Invalidate grocery templates
        ref.invalidate(groceryTemplatesProvider(currentFamily.id));
        // Note: taskTemplatesProvider is a FutureProvider, so we can't invalidate it directly
        // It will refresh on next access, but templates are less critical for real-time updates
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    // Re-register global callbacks whenever the family changes
    // This ensures callbacks are always available with the current family
    ref.listen(currentFamilyProvider, (previous, next) {
      if (next != null) {
        _registerGlobalCallbacks();
      }
    });

    return ScreenUtilInit(
      designSize: const Size(
        ResponsiveHelper.designWidth,
        ResponsiveHelper.designHeight,
      ),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              TextScalingClamp.clamp(
                MediaQuery.of(context).textScaler.scale(1.0),
              ),
            ),
          ),
          child: GestureDetector(
            // Dismiss keyboard when tapping outside input fields
            onTap: () {
              // Unfocus any focused text field
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.opaque,
            child: Consumer(
              builder: (context, ref, child) {
                final themeMode = ref.watch(themeModeProvider);
                return MaterialApp.router(
                  title: 'MyFamily',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: themeMode,
                  routerConfig: router,
                );
              },
            ),
          ),
        );
      },
    );
  }
}
