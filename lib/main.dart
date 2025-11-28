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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required for FCM)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase is not configured, continue without it
    // Push notifications will fail gracefully
    print('Firebase initialization failed: $e');
    print('Note: Push notifications require Firebase setup. See PUSH_NOTIFICATIONS_SETUP.md');
    print('Run: flutterfire configure');
  }
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

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
    // Load theme preference from user profile after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadThemePreference();
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

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    
    return ScreenUtilInit(
      designSize: const Size(ResponsiveHelper.designWidth, ResponsiveHelper.designHeight),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(TextScalingClamp.clamp(
              MediaQuery.of(context).textScaler.scale(1.0),
            )),
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
