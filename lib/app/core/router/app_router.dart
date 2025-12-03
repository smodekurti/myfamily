import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../constants/app_constants.dart';
import '../extensions/user_extensions.dart';
import '../../common/widgets/avatar_widget.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/consent_page.dart';
import '../../features/family/presentation/pages/get_started_page.dart';
import '../../features/family/presentation/pages/family_selection_page.dart';
import '../../features/family/presentation/pages/family_setup_page.dart';
import '../../features/family/presentation/pages/create_family_page.dart';
import '../../features/family/presentation/pages/join_family_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/tasks/presentation/pages/tasks_page.dart';
import '../../features/tasks/presentation/pages/create_task_page.dart';
import '../../features/tasks/presentation/pages/edit_task_page.dart';
import '../../data/models/task_model.dart';
import '../../features/groceries/presentation/pages/groceries_page.dart';
import '../../features/groceries/presentation/pages/grocery_list_page.dart';
import '../../features/groceries/presentation/pages/grocery_list_select_page.dart';
import '../../features/groceries/presentation/pages/grocery_template_detail_page.dart';
import '../../features/groceries/presentation/pages/grocery_template_create_page.dart';
import '../../features/groceries/presentation/pages/grocery_templates_manage_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/edit_profile_page.dart';
import '../../features/family/presentation/pages/family_settings_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/help_page.dart';
import '../../features/gamification/presentation/pages/leaderboard_page.dart';
import '../../features/gamification/presentation/pages/points_history_page.dart';
import '../../features/gamification/presentation/pages/achievements_page.dart';
import '../../features/onboarding/presentation/pages/walkthrough_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final routerState = ref.watch(routerStateProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      // Allow splash screen to show
      if (state.matchedLocation == AppConstants.routeSplash) {
        return null;
      }
      
      switch (routerState) {
        case RouterState.unauthenticated:
          // Redirect to auth pages
          if (state.matchedLocation.startsWith(AppConstants.routeAuth)) {
            return null;
          }
          return AppConstants.routeAuth;
          
        case RouterState.loading:
          // While loading, stay on splash or allow auth pages
          if (state.matchedLocation == AppConstants.routeSplash ||
              state.matchedLocation.startsWith(AppConstants.routeAuth)) {
            return null;
          }
          return AppConstants.routeSplash;
          
        case RouterState.authenticatedWithoutFamily:
          // Check if user needs consent (either no consent or version mismatch)
          final consentRepo = ref.watch(consentRepositoryProvider);
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            final needsConsent = consentRepo.needsConsent(currentUser.id);
            needsConsent.then((needs) {
              if (needs && state.matchedLocation != AppConstants.routeConsent) {
                // Will be handled by redirect logic below
              }
            });
            // For now, check synchronously if user has consented at all
            final userVersion = authRepo.getUserConsentVersion();
            if (userVersion == null) {
              // User hasn't consented at all, redirect to consent page
              if (state.matchedLocation == AppConstants.routeConsent) {
                return null;
              }
              return AppConstants.routeConsent;
            }
          }
          // User has given consent, redirect to get started
          if (state.matchedLocation == AppConstants.routeGetStarted ||
              state.matchedLocation.startsWith(AppConstants.routeFamilySetup)) {
            return null;
          }
          return AppConstants.routeGetStarted;
          
        case RouterState.authenticatedWithFamily:
          // Check if user needs consent (either no consent or version mismatch)
          final currentUser = ref.read(currentUserProvider);
          if (currentUser != null) {
            // Check synchronously if user has consented at all
            final userVersion = authRepo.getUserConsentVersion();
            if (userVersion == null) {
              // User hasn't consented at all, redirect to consent page
              if (state.matchedLocation == AppConstants.routeConsent) {
                return null;
              }
              return AppConstants.routeConsent;
            }
            // If user has a version, we'll check version mismatch in the consent page itself
            // For now, allow through - the consent page will handle version checks
            
            // Check if user has completed walkthrough
            if (!authRepo.hasCompletedWalkthrough()) {
              // User hasn't completed walkthrough, redirect to walkthrough page
              if (state.matchedLocation == AppConstants.routeWalkthrough) {
                return null;
              }
              return AppConstants.routeWalkthrough;
            }
          }
          // User has given consent and completed walkthrough, proceed with normal flow
          // User has one or more families - always show family selection first
          
          // If user is trying to access auth/get-started/consent/walkthrough, redirect to family selection
          if (state.matchedLocation.startsWith(AppConstants.routeAuth) ||
              state.matchedLocation == AppConstants.routeGetStarted ||
              state.matchedLocation == AppConstants.routeConsent ||
              state.matchedLocation == AppConstants.routeWalkthrough) {
            return AppConstants.routeFamilySelection;
          }
          
          // Allow access to family selection and family setup pages
          if (state.matchedLocation == AppConstants.routeFamilySelection ||
              state.matchedLocation.startsWith(AppConstants.routeFamilySetup)) {
            return null;
          }
          
          // For main app routes, only allow if a family has been selected
          // Check currentFamilyIdProvider directly to avoid race condition with loading family data
          final familyId = ref.read(currentFamilyIdProvider);
          if (familyId == null) {
            // No family selected yet, redirect to family selection
            return AppConstants.routeFamilySelection;
          }
          
          // Allow access to main app routes (including Tasks, Profile, Family Settings, Settings, Help, Leaderboard)
          if (state.matchedLocation.startsWith(AppConstants.routeHome) ||
              state.matchedLocation.startsWith(AppConstants.routeTasks) ||
              state.matchedLocation.startsWith(AppConstants.routeGroceries) ||
              state.matchedLocation.startsWith('/grocery-list') ||
              state.matchedLocation.startsWith('/grocery-template') ||
              state.matchedLocation.startsWith(AppConstants.routeCalendar) ||
              state.matchedLocation.startsWith(AppConstants.routeProfile) ||
              state.matchedLocation == AppConstants.routeFamilySettings ||
              state.matchedLocation == AppConstants.routeSettings ||
              state.matchedLocation == AppConstants.routeHelp ||
              state.matchedLocation == AppConstants.routeLeaderboard ||
              state.matchedLocation == AppConstants.routePointsHistory) {
            return null;
          }
          
          // Default to family selection if route not matched
          return AppConstants.routeFamilySelection;
      }
    },
    routes: [
      // Splash route
      GoRoute(
        path: AppConstants.routeSplash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),
      
      // Auth routes
      GoRoute(
        path: AppConstants.routeWelcome,
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppConstants.routeAuth,
        name: 'auth',
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppConstants.routeSignUp,
        name: 'sign-up',
        builder: (context, state) => const SignUpPage(),
      ),
      GoRoute(
        path: AppConstants.routeConsent,
        name: 'consent',
        builder: (context, state) => const ConsentPage(),
      ),
      GoRoute(
        path: AppConstants.routeWalkthrough,
        name: 'walkthrough',
        builder: (context, state) => const WalkthroughPage(),
      ),
      
      // Get Started / Family setup routes
      GoRoute(
        path: AppConstants.routeGetStarted,
        name: 'get-started',
        builder: (context, state) => const GetStartedPage(),
      ),
      GoRoute(
        path: AppConstants.routeFamilySelection,
        name: 'family-selection',
        builder: (context, state) => const FamilySelectionPage(),
      ),
      GoRoute(
        path: AppConstants.routeFamilySetup,
        name: 'family-setup',
        builder: (context, state) => const FamilySetupPage(),
      ),
      GoRoute(
        path: AppConstants.routeCreateFamily,
        name: 'create-family',
        builder: (context, state) => const CreateFamilyPage(),
      ),
      GoRoute(
        path: AppConstants.routeJoinFamily,
        name: 'join-family',
        builder: (context, state) => const JoinFamilyPage(),
      ),
      
      // Main app routes with bottom navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          GoRoute(
            path: AppConstants.routeHome,
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppConstants.routeTasks,
            name: 'tasks',
            builder: (context, state) {
              // Pass query parameters to TasksPage
              final filter = state.uri.queryParameters['filter'];
              return TasksPage(filter: filter);
            },
          ),
          GoRoute(
            path: AppConstants.routeCreateTask,
            name: 'create-task',
            builder: (context, state) {
              final category = state.uri.queryParameters['category'];
              return CreateTaskPage(initialCategory: category);
            },
          ),
          GoRoute(
            path: AppConstants.routeEditTask,
            name: 'edit-task',
            builder: (context, state) {
              final taskJson = state.extra as Map<String, dynamic>?;
              if (taskJson == null) {
                // If no task provided, go back
                return const TasksPage();
              }
              // Convert JSON to TaskModel
              final task = TaskModelHelpers.fromSupabase(taskJson);
              return EditTaskPage(task: task);
            },
          ),
          GoRoute(
            path: AppConstants.routeGroceries,
            name: 'groceries',
            builder: (context, state) => const GroceriesPage(),
          ),
          GoRoute(
            path: '/grocery-list/:listId',
            name: 'grocery-list',
            builder: (context, state) {
              final listId = state.pathParameters['listId']!;
              final from = state.uri.queryParameters['from'];
              return GroceryListPage(listId: listId, from: from);
            },
          ),
          GoRoute(
            path: '/grocery-list-select',
            name: 'grocery-list-select',
            builder: (context, state) => const GroceryListSelectPage(),
          ),
          GoRoute(
            path: '/grocery-template/create',
            name: 'grocery-template-create',
            builder: (context, state) => const GroceryTemplateCreatePage(),
          ),
          GoRoute(
            path: '/grocery-template/:templateId',
            name: 'grocery-template-detail',
            builder: (context, state) {
              final templateId = state.pathParameters['templateId']!;
              return GroceryTemplateDetailPage(templateId: templateId);
            },
          ),
          GoRoute(
            path: AppConstants.routeGroceryTemplatesManage,
            name: 'grocery-templates-manage',
            builder: (context, state) => const GroceryTemplatesManagePage(),
          ),
          GoRoute(
            path: AppConstants.routeCalendar,
            name: 'calendar',
            builder: (context, state) => const CalendarPage(),
          ),
          GoRoute(
            path: AppConstants.routeProfile,
            name: 'profile',
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: AppConstants.routeEditProfile,
            name: 'edit-profile',
            builder: (context, state) => const EditProfilePage(),
          ),
          GoRoute(
            path: AppConstants.routeFamilySettings,
            name: 'family-settings',
            builder: (context, state) => const FamilySettingsPage(),
          ),
          GoRoute(
            path: AppConstants.routeSettings,
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: AppConstants.routeHelp,
            name: 'help',
            builder: (context, state) => const HelpPage(),
          ),
          GoRoute(
            path: AppConstants.routeLeaderboard,
            name: 'leaderboard',
            builder: (context, state) => const LeaderboardPage(),
          ),
          GoRoute(
            path: AppConstants.routePointsHistory,
            name: 'points-history',
            builder: (context, state) => const PointsHistoryPage(),
          ),
          GoRoute(
            path: AppConstants.routeAchievements,
            name: 'achievements',
            builder: (context, state) => const AchievementsPage(),
          ),
        ],
      ),
    ],
  );
});

/// Main shell with bottom navigation
class MainShell extends ConsumerWidget {
  final Widget child;
  
  const MainShell({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    // Calculate current index based on route
    int currentIndex = 0;
    if (currentRoute == AppConstants.routeHome) {
      currentIndex = 0;
    } else if (currentRoute == AppConstants.routeTasks || 
               currentRoute == AppConstants.routeCreateTask) {
      currentIndex = 1;
    } else if (currentRoute == AppConstants.routeGroceries) {
      currentIndex = 2;
    } else if (currentRoute == AppConstants.routeCalendar) {
      currentIndex = 3;
    }
    
    // Update navigation index provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(navigationIndexProvider) != currentIndex) {
        ref.read(navigationIndexProvider.notifier).state = currentIndex;
      }
    });
    
    // Define navigation items - always include Tasks
    final List<BottomNavigationBarItem> items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.task_outlined),
        activeIcon: Icon(Icons.task),
        label: 'Tasks',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart_outlined),
        activeIcon: Icon(Icons.shopping_cart),
        label: 'Shopping',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.calendar_today_outlined),
        activeIcon: Icon(Icons.calendar_today),
        label: 'Calendar',
      ),
    ];
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
      appBar: _buildAppBar(context, ref),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).state = index;
          
          // Navigation: [Home, Tasks, Shopping, Calendar]
          switch (index) {
            case 0:
              context.go(AppConstants.routeHome);
              break;
            case 1:
              context.go(AppConstants.routeTasks);
              break;
            case 2:
              context.go(AppConstants.routeGroceries);
              break;
            case 3:
              context.go(AppConstants.routeCalendar);
              break;
          }
        },
        items: items,
      ),
      drawer: _buildDrawer(context, ref),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;
    
    // Get page title based on route
    String title = 'Family Wall';
    bool showSearch = false;
    if (currentRoute == AppConstants.routeHome) {
      title = 'Family Wall';
    } else if (currentRoute == AppConstants.routeTasks) {
      title = 'Household Chores';
      showSearch = true;
    } else if (currentRoute == AppConstants.routeCreateTask) {
      title = 'New Chore';
    } else if (currentRoute == AppConstants.routeGroceries) {
      title = 'Shopping';
      showSearch = true;
    } else if (currentRoute == AppConstants.routeCalendar) {
      title = 'Calendar';
      showSearch = true;
    } else if (currentRoute == AppConstants.routeProfile || 
               currentRoute == AppConstants.routeEditProfile) {
      title = 'Profile';
    }
    
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(title),
      centerTitle: true,
      actions: [
        // Search icon (only on searchable pages)
        if (showSearch)
          Consumer(
            builder: (context, ref, child) {
              final searchMode = ref.watch(searchModeProvider);
              return IconButton(
                icon: Icon(searchMode ? Icons.close : Icons.search),
                onPressed: () {
                  // Toggle search mode
                  ref.read(searchModeProvider.notifier).state = !searchMode;
                  if (!searchMode) {
                    // Clear search when closing
                    ref.read(searchQueryProvider.notifier).state = '';
                  }
                },
              );
            },
          ),
        // Profile icon
        GestureDetector(
          onTap: () => context.go(AppConstants.routeProfile),
          child: Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: SizedBox(
              width: 32,
              height: 32,
              child: AvatarWidget(
                avatarPath: currentUser?.avatarUrl,
                radius: 16,
                displayName: currentUser?.displayNameOrEmail,
                backgroundColor: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Drawer header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
              child: Row(
                children: [
                  AvatarWidget(
                    avatarPath: currentUser?.avatarUrl,
                    radius: 24,
                    displayName: currentUser?.displayNameOrEmail,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.displayNameOrEmail ?? 'User',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (currentUser?.email != null)
                          Text(
                            currentUser!.email!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.emoji_events,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Leaderboard'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeLeaderboard);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.military_tech,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Achievements'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeAchievements);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.shopping_bag,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Shopping Templates'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeGroceryTemplatesManage);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Manage Profile'),
                    onTap: () {
                      Navigator.pop(context);
                      context.go(AppConstants.routeEditProfile);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.family_restroom,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Family Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeFamilySettings);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.settings,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeSettings);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.help_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Help & Support'),
                    onTap: () {
                      Navigator.pop(context);
                      context.push(AppConstants.routeHelp);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.logout,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: Text(
                      'Log Out',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final authRepo = ref.read(authRepositoryProvider);
                      await authRepo.signOut();
                      if (context.mounted) {
                        context.go(AppConstants.routeWelcome);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
