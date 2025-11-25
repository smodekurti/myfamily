import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/family_model.dart';
import 'package:intl/intl.dart';

// Filter state provider
final taskFilterProvider = StateProvider<String>((ref) => 'all');

class TasksPage extends ConsumerStatefulWidget {
  final String? filter;
  
  const TasksPage({super.key, this.filter});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  @override
  void initState() {
    super.initState();
    // Set filter from query parameter if provided
    if (widget.filter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(taskFilterProvider.notifier).state = widget.filter!;
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh family members when page becomes visible to ensure avatars are up to date
    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily != null) {
      // Invalidate to force refresh of family members (which fetches latest user data)
      ref.invalidate(familyMembersProvider(currentFamily.id));
    }
  }


  @override
  Widget build(BuildContext context) {
    debugPrint('📋 TasksPage: Building...');
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    debugPrint('📋 TasksPage: currentFamily = ${currentFamily?.name}, currentUser = ${currentUser?.id}');
    final filter = ref.watch(taskFilterProvider);
    
    if (currentFamily == null) {
      return BackgroundWidget(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final familyTasks = ref.watch(familyTasksProvider(currentFamily.id));
    // Watch family members to ensure stream is active and updates
    final familyMembers = ref.watch(familyMembersProvider(currentFamily.id));

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.padding(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // This Week's Progress Section
                _buildProgressSection(context, ref, currentFamily.id),
                
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Filter Buttons
                _buildFilterButtons(context, filter),
                
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Upcoming Chores Section
                Text(
                  'Upcoming Chores',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Tasks List
                familyTasks.when(
                  data: (tasks) {
                    debugPrint('📋 TasksPage: Got ${tasks.length} tasks');
                    final filteredTasks = _filterTasks(tasks, filter, currentUser?.id);
                    debugPrint('📋 TasksPage: Filtered to ${filteredTasks.length} tasks');
                    final isEmpty = filteredTasks.isEmpty;
                    
                    if (isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    final members = familyMembers.when(
                      data: (m) {
                        debugPrint('📋 TasksPage: Got ${m.length} family members');
                        return m;
                      },
                      loading: () => <FamilyMemberModel>[],
                      error: (_, __) => <FamilyMemberModel>[],
                    );
                    return Column(
                      children: filteredTasks.map((task) {
                        debugPrint('📋 TasksPage: Building card for task ${task.id}, assignedTo: ${task.assignedTo}');
                        return _buildChoreCard(
                          context,
                          ref,
                          task,
                          members,
                          currentFamily.id,
                          currentUser?.id,
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(80)), // Space for FAB
              ],
            ),
          ),
        ),
        floatingActionButton: familyTasks.when(
          data: (tasks) {
            final filteredTasks = _filterTasks(tasks, filter, currentUser?.id);
            // Only show FAB if there are tasks (not in empty state)
            if (filteredTasks.isEmpty) {
              return null; // Hide FAB when empty state button is visible
            }
            return FloatingActionButton(
              onPressed: () {
                context.push(AppConstants.routeCreateTask);
              },
              child: const Icon(Icons.add),
            );
          },
          loading: () => null, // Hide FAB while loading
          error: (_, __) => FloatingActionButton(
            onPressed: () {
              context.push(AppConstants.routeCreateTask);
            },
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context, WidgetRef ref, String familyId) {
    final tasks = ref.watch(familyTasksProvider(familyId));
    
    return tasks.when(
      data: (taskList) {
        final totalTasks = taskList.length;
        
        // If no tasks, show a different message
        if (totalTasks == 0) {
          return Card(
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: ResponsiveHelper.borderRadius(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: ResponsiveHelper.w(1),
              ),
            ),
            elevation: 0,
            child: Padding(
              padding: ResponsiveHelper.padding(all: 16),
              child: Column(
                children: [
                  Text(
                    'This Week\'s Progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  Icon(
                    Icons.task_outlined,
                    size: ResponsiveHelper.iconSize(40),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                  SizedBox(height: ResponsiveHelper.h(12)),
                  Text(
                    'No tasks yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Text(
                    'Create your first chore to get started!',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        
        final completedTasks = taskList.where((t) => t.status == 'completed').length;
        final progress = completedTasks / totalTasks;
        final percentage = (progress * 100).round();
        
        // Get motivational message based on percentage
        final message = _getProgressMessage(percentage);
        final statusText = percentage == 100 ? 'Done!' : 'In Progress';
        
        return Card(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: ResponsiveHelper.borderRadius(12),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              width: ResponsiveHelper.w(1),
            ),
          ),
          elevation: 0,
          child: Padding(
            padding: ResponsiveHelper.padding(all: 16),
            child: Column(
              children: [
                Text(
                  'This Week\'s Progress',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                // Circular Progress - Centered (smaller)
                Center(
                  child: SizedBox(
                    width: ResponsiveHelper.w(80),
                    height: ResponsiveHelper.h(80),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background circle
                        SizedBox(
                          width: ResponsiveHelper.w(80),
                          height: ResponsiveHelper.h(80),
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: ResponsiveHelper.w(8),
                            backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        // Percentage text
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$percentage%',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              statusText,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: ResponsiveHelper.sp(10),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(12)),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _getProgressMessage(int percentage) {
    if (percentage == 100) {
      return 'Great work, family!';
    } else if (percentage >= 75) {
      return 'Great work, family!';
    } else if (percentage >= 50) {
      return 'Great work, family!';
    } else if (percentage >= 25) {
      return 'Great work, family!';
    } else if (percentage > 0) {
      return 'Great work, family!';
    } else {
      return 'Let\'s get started!';
    }
  }

  Widget _buildFilterButtons(BuildContext context, String currentFilter) {
    final filters = [
      {'id': 'all', 'label': 'All Chores'},
      {'id': 'my', 'label': 'My Chores'},
      {'id': 'today', 'label': 'Due Today'},
      {'id': 'completed', 'label': 'Completed'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = currentFilter == filter['id'];
          return Padding(
            padding: EdgeInsets.only(right: ResponsiveHelper.w(12)),
            child: Material(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).cardColor,
              borderRadius: ResponsiveHelper.borderRadius(20),
              child: InkWell(
                onTap: () {
                  ref.read(taskFilterProvider.notifier).state = filter['id']!;
                },
                borderRadius: ResponsiveHelper.borderRadius(20),
                child: Padding(
                  padding: ResponsiveHelper.padding(horizontal: 16, vertical: 10),
                  child: Text(
                    filter['label']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks, String filter, String? currentUserId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    switch (filter) {
      case 'my':
        return tasks.where((t) => t.assignedTo == currentUserId && t.status != 'completed').toList();
      case 'today':
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          final due = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
          return due == today && t.status != 'completed';
        }).toList();
      case 'completed':
        return tasks.where((t) => t.status == 'completed').toList();
      default:
        // "All Chores" - show all tasks including completed
        return tasks;
    }
  }

  Widget _buildChoreCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    debugPrint('🏗️ _buildChoreCard: Building card for task ${task.id}, assignedTo: ${task.assignedTo}, members count: ${members.length}');
    final assignedMember = members.firstWhere(
      (m) => m.uid == task.assignedTo,
      orElse: () {
        debugPrint('⚠️ _buildChoreCard: No member found for ${task.assignedTo}, using fallback');
        return const FamilyMemberModel(
          uid: '',
          displayName: '',
          role: 'member',
          points: 0,
        );
      },
    );
    
    debugPrint('👤 _buildChoreCard: assignedMember.uid = ${assignedMember.uid}, displayName = ${assignedMember.displayName}, photoURL = ${assignedMember.photoURL}');
    
    // Use assignedMember.photoURL as initial fallback
    // The Consumer will watch the userProfileProvider and update when it loads
    final initialAvatarUrl = assignedMember.photoURL;
    
    // Determine status and color
    String statusText;
    Color statusColor;
    Color ribbonColor;
    
    if (task.status == 'completed') {
      statusText = 'Done';
      statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      ribbonColor = Theme.of(context).colorScheme.primary; // Teal for completed
    } else if (task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      final difference = due.difference(today).inDays;
      
      if (difference < 0) {
        statusText = 'Overdue';
        statusColor = Colors.orange;
        ribbonColor = Colors.orange; // Orange for overdue
      } else if (difference == 0) {
        statusText = 'Due Today';
        statusColor = Colors.blue;
        ribbonColor = Colors.blue; // Blue for due today
      } else {
        final weekday = DateFormat('EEEE').format(task.dueDate!);
        statusText = 'Due $weekday';
        statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
        ribbonColor = Theme.of(context).colorScheme.secondary.withOpacity(0.5); // Subtle color for future dates
      }
    } else {
      statusText = 'No due date';
      statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      ribbonColor = Theme.of(context).colorScheme.primary.withOpacity(0.3); // Subtle teal for no due date
    }


    return Card(
      margin: ResponsiveHelper.padding(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: ResponsiveHelper.w(1),
        ),
      ),
      elevation: 0,
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          // Colored ribbon on the left
          Container(
            width: ResponsiveHelper.w(4),
            decoration: BoxDecoration(
              color: ribbonColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveHelper.r(12)),
                bottomLeft: Radius.circular(ResponsiveHelper.r(12)),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: ResponsiveHelper.padding(all: 16),
              child: Row(
                children: [
                  // Checkbox - outside InkWell to prevent tap interference
                  Checkbox(
                    value: task.status == 'completed',
                    onChanged: (value) async {
                      final taskActions = ref.read(taskActionsProvider);
                      if (value == true) {
                        await taskActions.completeTask(task.id);
                      } else {
                        await taskActions.updateTask(taskId: task.id, status: 'pending');
                      }
                      // Refresh the list and family members (for points update)
                      ref.invalidate(familyTasksProvider(familyId));
                      ref.invalidate(tasksDueTodayProvider(familyId));
                      ref.invalidate(familyMembersProvider(familyId));
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveHelper.borderRadius(4),
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.w(12)),
                  
                  // Task details - wrapped in InkWell for tap navigation
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        // Navigate to grocery list if grocery task, else task detail
                        if (task.category == 'grocery' && task.categoryData?['groceryListId'] != null) {
                          context.push('/grocery-list/${task.categoryData!['groceryListId']}?from=task');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Task: ${task.title}')),
                          );
                        }
                      },
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    Text(
                      task.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: task.status == 'completed'
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.status == 'completed'
                            ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(4)),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Assigned person avatar (smaller size)
                  // Always show avatar if task has assignedTo, even if member not found in list
                  if (task.assignedTo.isNotEmpty)
                Builder(
                  builder: (context) {
                    debugPrint('🔄 Building avatar Consumer for task ${task.id}, assignedTo: ${task.assignedTo}');
                    return Consumer(
                      builder: (context, ref, child) {
                        // Watch the user profile provider to get latest avatar URL
                        final userProfileAsync = ref.watch(userProfileProvider(task.assignedTo));
                        // Get display name from assignedMember if available, otherwise from user profile
                        String displayName = assignedMember.displayName.isNotEmpty
                            ? assignedMember.displayName
                            : '?';
                        
                        debugPrint('👤 Consumer built for task ${task.id}, assignedTo: ${task.assignedTo}, state: ${userProfileAsync.hasValue ? "hasValue" : userProfileAsync.isLoading ? "loading" : "error"}');
                        
                        // Use when() to handle all states and ensure proper rebuilds
                        return userProfileAsync.when(
                      data: (profile) {
                        // Use profile data if available, otherwise fallback
                        final avatarUrl = profile?.photoURL ?? initialAvatarUrl;
                        final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
                        // Update display name from profile if available
                        if (profile?.displayName != null && profile!.displayName.isNotEmpty) {
                          displayName = profile.displayName;
                        }
                        
                        debugPrint('🖼️ Avatar DATA for task ${task.id}, assignedTo: ${task.assignedTo}, hasPhoto: $hasPhoto, avatarUrl: $avatarUrl, displayName: $displayName');
                        
                        final photoUrl = avatarUrl; // Local variable for type safety
                        return CircleAvatar(
                          radius: ResponsiveHelper.r(16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: hasPhoto && photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('❌ Failed to load avatar image for ${task.assignedTo}: $exception');
                          },
                          child: hasPhoto
                              ? null
                              : Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.sp(12),
                                  ),
                                ),
                        );
                      },
                      loading: () {
                        final avatarUrl = initialAvatarUrl;
                        final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
                        
                        debugPrint('🖼️ Avatar LOADING for task ${task.id}, assignedTo: ${task.assignedTo}, hasPhoto: $hasPhoto, avatarUrl: $avatarUrl');
                        
                        final photoUrl = avatarUrl; // Local variable for type safety
                        return CircleAvatar(
                          radius: ResponsiveHelper.r(16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: hasPhoto && photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('❌ Failed to load avatar image (loading) for ${task.assignedTo}: $exception');
                          },
                          child: hasPhoto
                              ? null
                              : Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.sp(12),
                                  ),
                                ),
                        );
                      },
                      error: (error, stack) {
                        final avatarUrl = initialAvatarUrl;
                        final hasPhoto = avatarUrl != null && avatarUrl.isNotEmpty;
                        
                        debugPrint('🖼️ Avatar ERROR for task ${task.id}, assignedTo: ${task.assignedTo}, error: $error, hasPhoto: $hasPhoto, avatarUrl: $avatarUrl');
                        
                        final photoUrl = avatarUrl; // Local variable for type safety
                        return CircleAvatar(
                          radius: ResponsiveHelper.r(16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: hasPhoto && photoUrl != null
                              ? NetworkImage(photoUrl)
                              : null,
                          onBackgroundImageError: (exception, stackTrace) {
                            debugPrint('❌ Failed to load avatar image (error) for ${task.assignedTo}: $exception');
                          },
                          child: hasPhoto
                              ? null
                              : Text(
                                  displayName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.sp(12),
                                  ),
                                ),
                        );
                      },
                    );
                      },
                    );
                  },
                )
                  else
                    CircleAvatar(
                      radius: ResponsiveHelper.r(16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(
                        Icons.person,
                        size: ResponsiveHelper.iconSize(16),
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  
                  // Edit button (only show if user can edit: created by OR assigned to AND task is not completed)
                  if (currentUserId != null && 
                      (task.createdBy == currentUserId || task.assignedTo == currentUserId) &&
                      task.status != 'completed')
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: ResponsiveHelper.iconSize(20),
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: () {
                        // Navigate to edit page with task data
                        final taskJson = TaskModelHelpers.toSupabase(task);
                        context.push(
                          AppConstants.routeEditTask,
                          extra: taskJson,
                        );
                      },
                      tooltip: 'Edit chore',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.padding(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.task_outlined,
              size: ResponsiveHelper.iconSize(60),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Text(
              'No chores found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(24)),
            ElevatedButton.icon(
              onPressed: () => context.push(AppConstants.routeCreateTask),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Chore'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
