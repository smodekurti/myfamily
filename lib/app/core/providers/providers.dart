import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/grocery_template_repository.dart';
import '../../data/repositories/grocery_list_repository.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/consent_repository.dart';
import '../../data/repositories/points_history_repository.dart';
import '../../data/repositories/achievement_repository.dart';
import '../../data/repositories/task_template_repository.dart';
import '../../data/repositories/announcement_repository.dart';
import '../../data/repositories/weather_repository.dart';
import '../../data/models/weather_model.dart';
import '../services/location_service.dart';
import '../services/offline_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/avatar_url_service.dart';
import '../../data/models/task_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/points_history_model.dart';
import '../../data/models/achievement_model.dart';
import '../../data/models/task_template_model.dart';
import '../../data/models/announcement_model.dart';
import '../utils/streak_calculator.dart';

/// Singleton repository instances to avoid provider evaluation issues
final _taskRepositoryInstance = TaskRepository();
final _familyRepositoryInstance = FamilyRepository();

/// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Biometric authentication service provider
final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

/// Avatar URL service provider
final avatarUrlServiceProvider = Provider<AvatarUrlService>((ref) {
  return AvatarUrlService();
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return _familyRepositoryInstance;
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return _taskRepositoryInstance;
});

final groceryTemplateRepositoryProvider = Provider<GroceryTemplateRepository>((ref) {
  return GroceryTemplateRepository();
});

final groceryListRepositoryProvider = Provider<GroceryListRepository>((ref) {
  return GroceryListRepository();
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return ConsentRepository();
});

final pointsHistoryRepositoryProvider = Provider<PointsHistoryRepository>((ref) {
  return PointsHistoryRepository();
});

final achievementRepositoryProvider = Provider<AchievementRepository>((ref) {
  return AchievementRepository();
});

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  return TaskTemplateRepository();
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final offlineServiceProvider = Provider<OfflineService>((ref) {
  return OfflineService();
});

/// Provider for current consent content
final consentContentProvider = FutureProvider<ConsentContent>((ref) {
  final consentRepo = ref.watch(consentRepositoryProvider);
  return consentRepo.getConsentContent();
});

/// Provider to check if user needs consent
final needsConsentProvider = FutureProvider<bool>((ref) {
  final consentRepo = ref.watch(consentRepositoryProvider);
  final currentUser = ref.watch(currentUserProvider);
  
  if (currentUser == null) return Future.value(true);
  
  return consentRepo.needsConsent(currentUser.id);
});

/// Auth providers
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.authStateChanges;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

final userProfileProvider = StreamProvider.family((ref, String uid) {
  final authRepo = ref.watch(authRepositoryProvider);
  return authRepo.streamUserProfile(uid);
});

/// Family providers
final userFamiliesProvider = StreamProvider.family((ref, String userId) {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamUserFamilies(userId);
});

final familyProvider = StreamProvider.family((ref, String familyId) {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamFamily(familyId);
});

final familyMembersProvider = StreamProvider.family((ref, String familyId) {
  // Use the singleton instance directly to avoid any provider evaluation issues
  return _familyRepositoryInstance.streamFamilyMembers(familyId);
});

final familyMemberProvider = StreamProvider.family((ref, (String familyId, String uid) params) {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamFamilyMember(
    familyId: params.$1,
    uid: params.$2,
  );
});

/// Current family provider (will be set based on user selection)
final currentFamilyIdProvider = StateProvider<String?>((ref) => null);

/// Generate invite code provider
final generateInviteCodeProvider = FutureProvider.family<String?, String>((ref, familyId) async {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.generateInviteCodeForFamily(familyId);
});

/// Generate child invite code provider
final generateChildInviteCodeProvider = FutureProvider.family<String?, String>((ref, familyId) async {
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.generateChildInviteCodeForFamily(familyId);
});

final currentFamilyProvider = Provider((ref) {
  final familyId = ref.watch(currentFamilyIdProvider);
  
  if (familyId == null) {
    return null;
  }
  
  final familyAsync = ref.watch(familyProvider(familyId));
  return familyAsync.when(
    data: (family) {
      return family;
    },
    loading: () {
      return null;
    },
    error: (error, stack) {
      return null;
    },
  );
});

/// App state providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return currentUser != null;
});

final hasFamilyProvider = Provider<bool>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return false;
  
  final userFamilies = ref.watch(userFamiliesProvider(currentUser.id));
  return userFamilies.when(
    data: (families) => families.isNotEmpty,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Router state provider that combines auth and family status
final routerStateProvider = Provider<RouterState>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  final isAuthenticated = currentUser != null;
  
  if (!isAuthenticated) {
    return RouterState.unauthenticated;
  }
  
  final userFamilies = ref.watch(userFamiliesProvider(currentUser.id));
  return userFamilies.when(
    data: (families) {
      if (families.isEmpty) {
        return RouterState.authenticatedWithoutFamily;
      } else {
        // User has one or more families - always show family selection
        return RouterState.authenticatedWithFamily;
      }
    },
    loading: () {
      return RouterState.loading;
    },
    error: (error, stack) {
      return RouterState.authenticatedWithoutFamily;
    },
  );
});

enum RouterState {
  unauthenticated,
  loading,
  authenticatedWithoutFamily,
  authenticatedWithFamily,
}

/// Theme provider - defaults to dark theme
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

/// Navigation provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Task providers
final familyTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, familyId) {
  // Get current user for role-based filtering
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser?.id;
  
  // Use the singleton instance directly to avoid any provider evaluation issues
  return _taskRepositoryInstance.streamTasksForFamily(familyId, userId: userId);
});

final userTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, userId) {
  final currentFamily = ref.watch(currentFamilyProvider);
  
  if (currentFamily == null) {
    return Stream.value([]);
  }
  
  // Use the singleton instance directly to avoid any provider evaluation issues
  return _taskRepositoryInstance.streamTasksForUser(userId, currentFamily.id);
});

final tasksDueTodayProvider = StreamProvider.family<List<TaskModel>, String>((ref, familyId) {
  // Get current user for role-based filtering
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser?.id;
  
  // Stream all tasks and filter for today's tasks
  // This will automatically update when tasks change in Supabase
  // The stream will emit whenever tasks are created, updated, or deleted
  // Use the singleton instance directly to avoid any provider evaluation issues
  return _taskRepositoryInstance.streamTasksForFamily(familyId, userId: userId).map((tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      if (task.dueDate == null || task.status == 'completed') return false;
      final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return due == today;
    }).toList();
  });
});

final taskStatsProvider = FutureProvider.family<Map<String, int>, String>((ref, familyId) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  return taskRepo.getTaskStats(familyId);
});

/// Task actions provider
final taskActionsProvider = Provider<TaskActions>((ref) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  return TaskActions(taskRepo);
});

class TaskActions {
  final TaskRepository _taskRepo;
  
  TaskActions(this._taskRepo);
  
  Future<TaskModel> createTask({
    required String title,
    String? description,
    required String assignedTo,
    required String createdBy,
    required String familyId,
    String status = 'pending',
    String priority = 'medium',
    String category = 'chore',
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int points = 10,
  }) async {
    return _taskRepo.createTask(
      title: title,
      description: description,
      assignedTo: assignedTo,
      createdBy: createdBy,
      familyId: familyId,
      status: status,
      priority: priority,
      category: category,
      categoryData: categoryData,
      dueDate: dueDate,
      points: points,
    );
  }
  
  Future<TaskModel> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    String? status,
    String? priority,
    String? category,
    Map<String, dynamic>? categoryData,
    DateTime? dueDate,
    int? points,
  }) async {
    return _taskRepo.updateTask(
      taskId: taskId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      status: status,
      priority: priority,
      category: category,
      categoryData: categoryData,
      dueDate: dueDate,
      points: points,
    );
  }
  
  Future<TaskModel> completeTask(String taskId) async {
    return _taskRepo.completeTask(taskId);
  }
  
  Future<void> deleteTask(String taskId) async {
    return _taskRepo.deleteTask(taskId);
  }
}

/// Announcement providers
final familyAnnouncementsProvider = StreamProvider.family<List<AnnouncementModel>, String>((ref, familyId) {
  final announcementRepo = ref.watch(announcementRepositoryProvider);
  // Get current user for role-based filtering
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser?.id;
  return announcementRepo.streamFamilyAnnouncements(familyId, userId: userId);
});

/// Calendar providers
final familyEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, familyId) {
  final calendarRepo = ref.watch(calendarRepositoryProvider);
  // Get current user for role-based filtering
  final currentUser = ref.watch(currentUserProvider);
  final userId = currentUser?.id;
  return calendarRepo.streamFamilyEvents(familyId, userId: userId);
});

/// Weekly points provider - calculates points earned in the last 7 days
final weeklyPointsProvider = FutureProvider.family<Map<String, int>, String>((ref, familyId) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final now = DateTime.now();
  final weekAgo = now.subtract(const Duration(days: 7));
  
  // Get all completed tasks in the last 7 days
  final allTasks = await taskRepo.getTasksForFamily(familyId);
  final weeklyTasks = allTasks.where((task) {
    if (task.status != 'completed' || task.completedAt == null) return false;
    return task.completedAt!.isAfter(weekAgo);
  }).toList();
  
  // Calculate points per user
  final weeklyPoints = <String, int>{};
  for (final task in weeklyTasks) {
    weeklyPoints[task.assignedTo] = (weeklyPoints[task.assignedTo] ?? 0) + task.points;
  }
  
  return weeklyPoints;
});

/// Grocery suggestions provider - suggests items from previous completed lists
final grocerySuggestionsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, familyId) async {
  final listRepo = ref.watch(groceryListRepositoryProvider);
  return await listRepo.getSuggestedItems(familyId);
});

// Search state providers
final searchModeProvider = StateProvider<bool>((ref) => false);
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Streak provider - calculates current and longest streaks for a user
final userStreakProvider = FutureProvider.family<Map<String, int>, (String userId, String familyId)>((ref, params) async {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final completedTasks = await taskRepo.getCompletedTasksForUser(params.$1, params.$2);
  return StreakCalculator.calculateStreaks(completedTasks);
});

/// Points history provider - gets points transaction history for a user
final userPointsHistoryProvider = FutureProvider.family<List<PointsHistoryModel>, (String userId, String familyId)>((ref, params) async {
  final historyRepo = ref.watch(pointsHistoryRepositoryProvider);
  return await historyRepo.getPointsHistoryForUser(
    userId: params.$1,
    familyId: params.$2,
  );
});

/// User achievements provider - gets all unlocked achievements for a user
final userAchievementsProvider = FutureProvider.family<List<AchievementModel>, (String userId, String familyId)>((ref, params) async {
  final achievementRepo = ref.watch(achievementRepositoryProvider);
  return await achievementRepo.getUserAchievements(
    userId: params.$1,
    familyId: params.$2,
  );
});

/// Selected weather location provider - stores user's selected location
/// null means use current location
final selectedWeatherLocationProvider = StateProvider<String?>((ref) => null);

/// Location provider - gets current device location
final currentLocationProvider = FutureProvider<Position?>((ref) async {
  final locationService = ref.watch(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

/// Weather provider - gets current weather for selected location, current location, or fallback city
final weatherProvider = FutureProvider<WeatherModel?>((ref) async {
  final weatherRepo = ref.watch(weatherRepositoryProvider);
  final selectedLocation = ref.watch(selectedWeatherLocationProvider);
  
  // If user has selected a specific location, use it
  if (selectedLocation != null && selectedLocation.isNotEmpty) {
    // Check if it's a zipcode (numeric, 4-10 digits)
    final isZipcode = RegExp(r'^\d{4,10}$').hasMatch(selectedLocation.trim());
    final weather = isZipcode
        ? await weatherRepo.getWeather(zipcode: selectedLocation.trim())
        : await weatherRepo.getWeather(cityName: selectedLocation);
    
    // If weather not found for selected location, clear the selection and fall back to default
    // This prevents the widget from disappearing and stops retrying the invalid location
    if (weather == null) {
      // Clear invalid selection to prevent retrying
      ref.read(selectedWeatherLocationProvider.notifier).state = null;
      // Fall back to default location
      return await weatherRepo.getWeather(cityName: AppConstants.defaultWeatherCity);
    }
    
    return weather;
  }
  
  // Otherwise, try to use current location
  final locationAsync = ref.watch(currentLocationProvider);
  
  return locationAsync.when(
    data: (position) async {
      if (position != null) {
        // Use current location
        return await weatherRepo.getWeather(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      } else {
        // Fallback to default city
        return await weatherRepo.getWeather(cityName: AppConstants.defaultWeatherCity);
      }
    },
    loading: () async {
      // While loading location, try default city
      return await weatherRepo.getWeather(cityName: AppConstants.defaultWeatherCity);
    },
    error: (error, stack) async {
      // On error, use default city
      return await weatherRepo.getWeather(cityName: AppConstants.defaultWeatherCity);
    },
  );
});

/// Task templates provider - gets all task templates for a family
final taskTemplatesProvider = FutureProvider.family<List<TaskTemplateModel>, String>((ref, familyId) async {
  final templateRepo = ref.watch(taskTemplateRepositoryProvider);
  return await templateRepo.getTemplatesForFamily(familyId);
});
