import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/family_repository.dart';
import '../../data/repositories/task_repository.dart';
import '../../data/repositories/grocery_template_repository.dart';
import '../../data/repositories/grocery_list_repository.dart';
import '../../data/repositories/calendar_repository.dart';
import '../../data/repositories/consent_repository.dart';
import '../../data/models/task_model.dart';
import '../../data/models/event_model.dart';

/// Repository providers
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  return FamilyRepository();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
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
  final familyRepo = ref.watch(familyRepositoryProvider);
  return familyRepo.streamFamilyMembers(familyId);
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
  print('🔍 CurrentFamilyProvider: familyId = $familyId');
  
  if (familyId == null) {
    print('🔍 CurrentFamilyProvider: No family ID set, returning null');
    return null;
  }
  
  final familyAsync = ref.watch(familyProvider(familyId));
  return familyAsync.when(
    data: (family) {
      print('🔍 CurrentFamilyProvider: Got family data: ${family?.name} (${family?.id})');
      return family;
    },
    loading: () {
      print('🔍 CurrentFamilyProvider: Loading family data...');
      return null;
    },
    error: (error, stack) {
      print('🔍 CurrentFamilyProvider: Error loading family: $error');
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
    print('🔍 RouterState: unauthenticated');
    return RouterState.unauthenticated;
  }
  
  final userFamilies = ref.watch(userFamiliesProvider(currentUser.id));
  return userFamilies.when(
    data: (families) {
      print('🔍 RouterState: authenticated, families count: ${families.length}');
      if (families.isEmpty) {
        return RouterState.authenticatedWithoutFamily;
      } else {
        // User has one or more families - always show family selection
        return RouterState.authenticatedWithFamily;
      }
    },
    loading: () {
      print('🔍 RouterState: loading');
      return RouterState.loading;
    },
    error: (error, stack) {
      print('🔍 RouterState: error - $error');
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

/// Theme provider
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Navigation provider
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Task providers
final familyTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, familyId) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  return taskRepo.streamTasksForFamily(familyId);
});

final userTasksProvider = StreamProvider.family<List<TaskModel>, String>((ref, userId) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  final currentFamily = ref.watch(currentFamilyProvider);
  
  if (currentFamily == null) {
    return Stream.value([]);
  }
  
  return taskRepo.streamTasksForUser(userId, currentFamily.id);
});

final tasksDueTodayProvider = StreamProvider.family<List<TaskModel>, String>((ref, familyId) {
  final taskRepo = ref.watch(taskRepositoryProvider);
  // Stream all tasks and filter for today's tasks
  // This will automatically update when tasks change in Supabase
  // The stream will emit whenever tasks are created, updated, or deleted
  return taskRepo.streamTasksForFamily(familyId).map((tasks) {
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

/// Calendar providers
final familyEventsProvider = StreamProvider.family<List<EventModel>, String>((ref, familyId) {
  final calendarRepo = ref.watch(calendarRepositoryProvider);
  return calendarRepo.streamFamilyEvents(familyId);
});
