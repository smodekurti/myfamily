import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/core/config/supabase_config.dart';
import 'app/core/theme/app_theme.dart';
import 'app/core/router/app_router.dart';
import 'app/common/responsive/responsive_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  
  
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

class MyFamilyApp extends ConsumerWidget {
  const MyFamilyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            child: MaterialApp.router(
              title: 'MyFamily',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark, // Default to dark theme to match screenshot
              routerConfig: router,
            ),
          ),
        );
      },
    );
  }
}
