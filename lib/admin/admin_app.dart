import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../app/core/theme/app_theme.dart';
import 'presentation/dashboard/admin_dashboard_page.dart';
import 'presentation/login/admin_login_page.dart';
import 'presentation/families/admin_families_page.dart';
import 'presentation/templates/admin_templates_page.dart';
import 'presentation/templates/admin_template_detail_page.dart';
import 'presentation/users/admin_users_page.dart';
import 'presentation/users/admin_user_detail_page.dart';
import 'presentation/families/admin_family_detail_page.dart';
import '../../app/core/providers/providers.dart';

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const AdminLoginPage(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/families',
          builder: (context, state) => const AdminFamiliesPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AdminFamilyDetailPage(familyId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/users',
          builder: (context, state) => const AdminUsersPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AdminUserDetailPage(userId: id);
              },
            ),
          ],
        ),
        GoRoute(
          path: '/templates',
          builder: (context, state) => const AdminTemplatesPage(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = state.pathParameters['id']!;
                return AdminTemplateDetailPage(templateId: id);
              },
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final session = Supabase.instance.client.auth.currentSession;
        final loggingIn = state.uri.toString() == '/login';

        if (session == null) {
          return loggingIn ? null : '/login';
        }

        // TODO: Check if user is admin role here?
        // For now, if logged in, go to dashboard.
        // We will enforce "Admin-only" in the dashboard logic or here causing a redirect if not admin.

        if (loggingIn) {
          return '/';
        }
        return null;
      },
    );

    return MaterialApp.router(
      title: 'MyFamily Admin',
      theme: AppTheme.lightTheme.copyWith(
        // Distinguish Admin App with a different primary color (e.g. Teal)
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
