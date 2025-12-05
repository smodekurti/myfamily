import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/permission_aware_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/widgets/modern_card.dart';
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/task_category.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../data/models/task_model.dart';
import '../../../../data/models/family_model.dart';

// Filter state provider - default to 'all' for "All Chores"
final taskFilterProvider = StateProvider<String>((ref) => 'all');

// View mode provider: 'list', 'simple_list', 'grid', 'grouped_category', 'grouped_assignee', 'grouped_due_date'
final taskViewModeProvider = StateProvider<String>((ref) => 'list');

class TasksPage extends ConsumerStatefulWidget {
  final String? filter;

  const TasksPage({super.key, this.filter});

  @override
  ConsumerState<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends ConsumerState<TasksPage> {
  final TextEditingController _searchController = TextEditingController();
  final Logger _logger = Logger();
  bool _showAllTasks = false;

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

    // Set up callback to refresh tasks when a task notification is received
    // This is a fallback when realtime stream isn't working
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          PushNotificationService().setTaskNotificationCallback(() {
            if (mounted) {
              ref.invalidate(familyTasksProvider(currentFamily.id));
              ref.invalidate(tasksDueTodayProvider(currentFamily.id));
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Don't clear the callback - let the global callback handle it
    // The global callback in main.dart will ensure it's always registered
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final filter = ref.watch(taskFilterProvider);
    final searchMode = ref.watch(searchModeProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    // Sync search controller with provider
    if (_searchController.text != searchQuery) {
      _searchController.text = searchQuery;
    }

    if (currentFamily == null) {
      return BackgroundWidget(
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final familyTasks = ref.watch(familyTasksProvider(currentFamily.id));
    final familyMembers = ref.watch(familyMembersProvider(currentFamily.id));

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Modern Header
              ModernHeader(
                title: 'Tasks',
                subtitle: 'Manage your family chores',
                actions: [
                  IconButton(
                    icon: Icon(
                      searchMode ? Icons.close_rounded : Icons.search_rounded,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      if (searchMode) {
                        ref.read(searchModeProvider.notifier).state = false;
                        ref.read(searchQueryProvider.notifier).state = '';
                        _searchController.clear();
                      } else {
                        ref.read(searchModeProvider.notifier).state = true;
                      }
                    },
                  ),
                ],
              ),

              // Search bar (shown when search mode is active)
              if (searchMode)
                Padding(
                  padding: ResponsiveHelper.padding(horizontal: 16, bottom: 16),
                  child: ModernCard(
                    padding: ResponsiveHelper.padding(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        border: InputBorder.none,
                        icon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state =
                                      '';
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        ref.read(searchQueryProvider.notifier).state = value;
                      },
                    ),
                  ),
                ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    final currentFamily = ref.read(currentFamilyProvider);
                    if (currentFamily != null) {
                      ref.invalidate(familyTasksProvider(currentFamily.id));
                      ref.invalidate(tasksDueTodayProvider(currentFamily.id));
                      ref.invalidate(taskStatsProvider(currentFamily.id));
                    }
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    padding: ResponsiveHelper.padding(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // This Week Status Section
                        if (!searchMode)
                          familyTasks.when(
                            data: (tasks) {
                              return Column(
                                children: [
                                  _buildThisWeekStatus(context, tasks),
                                  SizedBox(height: ResponsiveHelper.h(24)),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                        // Upcoming Chores Section Header
                        _buildUpcomingChoresHeader(context, ref),
                        SizedBox(height: ResponsiveHelper.h(16)),

                        // Tasks List
                        familyTasks.when(
                          data: (tasks) {
                            var filteredTasks = _filterTasks(
                              tasks,
                              filter,
                              currentUser?.id,
                            );

                            if (searchMode && searchQuery.isNotEmpty) {
                              filteredTasks = _searchTasks(
                                filteredTasks,
                                searchQuery,
                              );
                            }

                            if (filteredTasks.isEmpty) {
                              return _buildEmptyState(context);
                            }

                            // Sort by earliest due date (null dates go to end)
                            final sortedTasks = List<TaskModel>.from(
                              filteredTasks,
                            );
                            sortedTasks.sort((a, b) {
                              if (a.dueDate == null && b.dueDate == null)
                                return 0;
                              if (a.dueDate == null)
                                return 1; // null dates go to end
                              if (b.dueDate == null) return -1;
                              return a.dueDate!.compareTo(
                                b.dueDate!,
                              ); // earliest first
                            });

                            // Limit to top 5 tasks if not showing all
                            final tasksToShow = _showAllTasks
                                ? sortedTasks
                                : sortedTasks.take(5).toList();
                            final hasMoreTasks = sortedTasks.length > 5;

                            final members = familyMembers.when(
                              data: (m) => m,
                              loading: () => <FamilyMemberModel>[],
                              error: (_, __) => <FamilyMemberModel>[],
                            );

                            final viewMode = ref.watch(taskViewModeProvider);

                            // Use the view mode to determine how to display tasks
                            if (viewMode == 'list') {
                              return Column(
                                children: [
                                  if (hasMoreTasks && !_showAllTasks)
                                    _buildViewAllLink(context),
                                  ...tasksToShow.map((task) {
                                    return _buildNewTaskCard(
                                      context,
                                      ref,
                                      task,
                                      members,
                                      currentFamily.id,
                                      currentUser?.id,
                                    );
                                  }).toList(),
                                  if (hasMoreTasks && _showAllTasks)
                                    _buildShowLessLink(context),
                                ],
                              );
                            } else {
                              // Use the existing _buildTasksView for other view modes
                              return Column(
                                children: [
                                  if (hasMoreTasks && !_showAllTasks)
                                    _buildViewAllLink(context),
                                  _buildTasksView(
                                    context,
                                    ref,
                                    tasksToShow,
                                    members,
                                    currentFamily.id,
                                    currentUser?.id,
                                    viewMode,
                                  ),
                                  if (hasMoreTasks && _showAllTasks)
                                    _buildShowLessLink(context),
                                ],
                              );
                            }
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) {
                            _logger.e(
                              'Tasks error: $error',
                              error: error,
                              stackTrace: stackTrace,
                            );
                            return Center(
                              child: Padding(
                                padding: ResponsiveHelper.padding(all: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: ResponsiveHelper.iconSize(48),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    SizedBox(height: ResponsiveHelper.h(16)),
                                    Text(
                                      'Error loading tasks',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(
                          height: ResponsiveHelper.h(80),
                        ), // Space for FAB
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: familyTasks.when(
          data: (tasks) {
            final filteredTasks = _filterTasks(tasks, filter, currentUser?.id);
            if (filteredTasks.isEmpty) {
              return null;
            }
            return PermissionAwareWidget(
              action: 'create_task',
              child: FloatingActionButton(
                onPressed: () => context.push(AppConstants.routeCreateTask),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveHelper.borderRadius(16),
                ),
                child: const Icon(Icons.add),
              ),
            );
          },
          loading: () => null,
          error: (_, __) => PermissionAwareWidget(
            action: 'create_task',
            child: FloatingActionButton(
              onPressed: () => context.push(AppConstants.routeCreateTask),
              backgroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: ResponsiveHelper.borderRadius(16),
              ),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThisWeekStatus(BuildContext context, List<TaskModel> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final overdueTasks = tasks.where((task) {
      if (task.status == 'completed' || task.dueDate == null) return false;
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return due.isBefore(today);
    }).length;

    final completedTasks = tasks.where((task) {
      if (task.status != 'completed') return false;
      return true;
    }).length;

    return ModernCard(
      padding: ResponsiveHelper.padding(all: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: ResponsiveHelper.iconSize(20),
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Text(
                'This Week',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: ResponsiveHelper.h(16)),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: ResponsiveHelper.padding(all: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$overdueTasks',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      Text(
                        'Overdue',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(12)),
              Expanded(
                child: Container(
                  padding: ResponsiveHelper.padding(all: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$completedTasks',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      Text(
                        'Completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingChoresHeader(BuildContext context, WidgetRef ref) {
    final viewMode = ref.watch(taskViewModeProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Upcoming Chores',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.list_rounded),
              iconSize: ResponsiveHelper.iconSize(24),
              tooltip: 'View options',
              onPressed: () {
                _showViewModeDialog(context, ref, viewMode);
              },
            ),
            IconButton(
              icon: const Icon(Icons.filter_list_rounded),
              iconSize: ResponsiveHelper.iconSize(24),
              tooltip: 'Filter options',
              onPressed: () {
                _showFilterDialog(context, ref);
              },
            ),
          ],
        ),
      ],
    );
  }

  void _showViewModeDialog(
    BuildContext context,
    WidgetRef ref,
    String currentMode,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveHelper.r(20)),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'View Options',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.view_list,
                        label: 'List',
                        mode: 'list',
                        isSelected: currentMode == 'list',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.format_list_bulleted,
                        label: 'Simple List',
                        mode: 'simple_list',
                        isSelected: currentMode == 'simple_list',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.grid_view,
                        label: 'Grid',
                        mode: 'grid',
                        isSelected: currentMode == 'grid',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.category,
                        label: 'Group by Category',
                        mode: 'grouped_category',
                        isSelected: currentMode == 'grouped_category',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.person,
                        label: 'Group by Assignee',
                        mode: 'grouped_assignee',
                        isSelected: currentMode == 'grouped_assignee',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildViewModeOption(
                        context,
                        ref,
                        icon: Icons.calendar_today,
                        label: 'Group by Due Date',
                        mode: 'grouped_due_date',
                        isSelected: currentMode == 'grouped_due_date',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String mode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(taskViewModeProvider.notifier).state = mode;
        Navigator.pop(context);
      },
      borderRadius: ResponsiveHelper.borderRadius(12),
      child: Container(
        padding: ResponsiveHelper.padding(all: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: ResponsiveHelper.borderRadius(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: ResponsiveHelper.w(2),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.iconSize(24),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: ResponsiveHelper.w(16)),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveHelper.iconSize(24),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(taskFilterProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ResponsiveHelper.r(20)),
        ),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Tasks',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFilterOption(
                        context,
                        ref,
                        icon: Icons.list_alt,
                        label: 'All Chores',
                        filter: 'all',
                        isSelected: currentFilter == 'all',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildFilterOption(
                        context,
                        ref,
                        icon: Icons.person,
                        label: 'My Chores',
                        filter: 'my',
                        isSelected: currentFilter == 'my',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildFilterOption(
                        context,
                        ref,
                        icon: Icons.today,
                        label: 'Due Today',
                        filter: 'today',
                        isSelected: currentFilter == 'today',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildFilterOption(
                        context,
                        ref,
                        icon: Icons.priority_high,
                        label: 'High Priority',
                        filter: 'high',
                        isSelected: currentFilter == 'high',
                      ),
                      SizedBox(height: ResponsiveHelper.h(12)),
                      _buildFilterOption(
                        context,
                        ref,
                        icon: Icons.check_circle,
                        label: 'Completed',
                        filter: 'completed',
                        isSelected: currentFilter == 'completed',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    BuildContext context,
    WidgetRef ref, {
    required IconData icon,
    required String label,
    required String filter,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(taskFilterProvider.notifier).state = filter;
        Navigator.pop(context);
      },
      borderRadius: ResponsiveHelper.borderRadius(12),
      child: Container(
        padding: ResponsiveHelper.padding(all: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: ResponsiveHelper.borderRadius(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: ResponsiveHelper.w(2),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.iconSize(24),
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
            ),
            SizedBox(width: ResponsiveHelper.w(16)),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveHelper.iconSize(24),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTaskCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    final assignedMember = members.firstWhere(
      (m) => m.uid == task.assignedTo,
      orElse: () => const FamilyMemberModel(
        uid: '',
        displayName: '',
        role: 'member',
        points: 0,
      ),
    );

    // Calculate overdue days
    String statusText;
    Color statusColor;
    if (task.status == 'completed') {
      statusText = 'Done';
      statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    } else if (task.dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final due = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      final difference = due.difference(today).inDays;

      if (difference < 0) {
        final daysOverdue = difference.abs();
        statusText = daysOverdue == 1
            ? '1 day overdue'
            : '$daysOverdue days overdue';
        statusColor = Theme.of(context).colorScheme.error;
      } else if (difference == 0) {
        statusText = 'Due today';
        statusColor = Theme.of(context).colorScheme.primary;
      } else {
        statusText = 'Due in $difference days';
        statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
      }
    } else {
      statusText = 'No due date';
      statusColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }

    final initialAvatarUrl = assignedMember.photoURL;
    final displayName = assignedMember.displayName.isNotEmpty
        ? assignedMember.displayName
        : '?';

    return ModernCard(
      margin: ResponsiveHelper.padding(bottom: 12),
      onTap: () {
        // Navigate to grocery list if grocery task, else task detail/edit page
        if (task.category == 'grocery' &&
            task.categoryData?['groceryListId'] != null) {
          final groceryListId = task.categoryData!['groceryListId'] as String;
          context.push('/grocery-list/$groceryListId?from=task');
        } else {
          // Navigate to task detail/edit page
          final taskJson = TaskModelHelpers.toSupabase(task);
          context.push(AppConstants.routeEditTask, extra: taskJson);
        }
      },
      child: ListTile(
        contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 4),
        leading: Transform.scale(
          scale: 1.2,
          child: Checkbox(
            value: task.status == 'completed',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            side: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              width: 1.5,
            ),
            onChanged: (value) async {
              final taskActions = ref.read(taskActionsProvider);
              if (value == true) {
                final canComplete = await _checkGroceryTaskComplete(
                  context,
                  task,
                );
                if (!canComplete) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Please check all items in the grocery list before completing this task.',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                  return;
                }
                final completedTask = await taskActions.completeTask(task.id);
                if (context.mounted && completedTask.points > 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: ResponsiveHelper.iconSize(20),
                          ),
                          SizedBox(width: ResponsiveHelper.w(8)),
                          Expanded(
                            child: Text(
                              '+${completedTask.points} points earned!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } else {
                await taskActions.updateTask(
                  taskId: task.id,
                  status: 'pending',
                );
              }
              ref.invalidate(familyTasksProvider(familyId));
              ref.invalidate(tasksDueTodayProvider(familyId));
              ref.invalidate(familyMembersProvider(familyId));
            },
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          task.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            decoration: task.status == 'completed'
                ? TextDecoration.lineThrough
                : null,
            color: task.status == 'completed'
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: ResponsiveHelper.h(4)),
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: ResponsiveHelper.iconSize(14),
                color: statusColor,
              ),
              SizedBox(width: ResponsiveHelper.w(4)),
              Text(
                statusText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (task.points > 0) ...[
                SizedBox(width: ResponsiveHelper.w(12)),
                Icon(
                  Icons.star_rounded,
                  size: ResponsiveHelper.iconSize(14),
                  color: Colors.amber,
                ),
                SizedBox(width: ResponsiveHelper.w(2)),
                Text(
                  '${task.points} pts',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (task.assignedTo.isNotEmpty)
              Consumer(
                builder: (context, ref, child) {
                  final userProfileAsync = ref.watch(
                    userProfileProvider(task.assignedTo),
                  );
                  return userProfileAsync.when(
                    data: (profile) {
                      final avatarUrl = profile?.photoURL ?? initialAvatarUrl;
                      final name = profile?.displayName ?? displayName;
                      return AvatarWidget(
                        avatarPath: avatarUrl,
                        radius: ResponsiveHelper.r(16),
                        displayName: name,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        textColor: Theme.of(
                          context,
                        ).colorScheme.onPrimaryContainer,
                      );
                    },
                    loading: () => AvatarWidget(
                      avatarPath: initialAvatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName: displayName,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                    error: (_, __) => AvatarWidget(
                      avatarPath: initialAvatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName: displayName,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  );
                },
              ),
            SizedBox(width: ResponsiveHelper.w(8)),
            IconButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(height: ResponsiveHelper.h(8)),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                        ListTile(
                          leading: const Icon(Icons.edit_rounded),
                          title: const Text('Edit Task'),
                          onTap: () {
                            Navigator.pop(context);
                            // Navigate to edit page
                            final taskJson = TaskModelHelpers.toSupabase(task);
                            context.push(
                              AppConstants.routeEditTask,
                              extra: taskJson,
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.delete_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          title: Text(
                            'Delete Task',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onTap: () async {
                            Navigator.pop(context);
                            // Confirm delete
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Task?'),
                                content: const Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              final taskActions = ref.read(taskActionsProvider);
                              await taskActions.deleteTask(task.id);
                              ref.invalidate(familyTasksProvider(familyId));
                              ref.invalidate(tasksDueTodayProvider(familyId));
                              ref.invalidate(taskStatsProvider(familyId));
                            }
                          },
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButtons(BuildContext context, String currentFilter) {
    final filters = [
      {'id': 'all', 'label': 'All Chores'},
      {'id': 'my', 'label': 'My Chores'},
      {'id': 'today', 'label': 'Due Today'},
      {'id': 'high', 'label': 'High Priority'},
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
                  padding: ResponsiveHelper.padding(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    filter['label']!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
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

  List<TaskModel> _filterTasks(
    List<TaskModel> tasks,
    String filter,
    String? currentUserId,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (filter) {
      case 'my':
        return tasks
            .where(
              (t) => t.assignedTo == currentUserId && t.status != 'completed',
            )
            .toList();
      case 'today':
        return tasks.where((t) {
          if (t.dueDate == null) return false;
          final due = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return due == today && t.status != 'completed';
        }).toList();
      case 'high':
        return tasks
            .where((t) => t.priority == 'high' && t.status != 'completed')
            .toList();
      case 'completed':
        return tasks.where((t) => t.status == 'completed').toList();
      default:
        // "All Chores" - show all tasks including completed
        return tasks;
    }
  }

  /// Build "View All" link to show all tasks
  Widget _buildViewAllLink(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _showAllTasks = true;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View All',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            Icon(
              Icons.arrow_downward,
              size: ResponsiveHelper.iconSize(16),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Build "Show Less" link to collapse back to top 5
  Widget _buildShowLessLink(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
      child: InkWell(
        onTap: () {
          setState(() {
            _showAllTasks = false;
          });
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Show Less',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            Icon(
              Icons.arrow_upward,
              size: ResponsiveHelper.iconSize(16),
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<TaskModel> _searchTasks(List<TaskModel> tasks, String query) {
    if (query.isEmpty) return tasks;

    final lowerQuery = query.toLowerCase();
    return tasks.where((task) {
      // Search in title
      if (task.title.toLowerCase().contains(lowerQuery)) return true;

      // Search in description
      if (task.description != null &&
          task.description!.toLowerCase().contains(lowerQuery))
        return true;

      // Search in category
      if (task.category.toLowerCase().contains(lowerQuery)) return true;

      return false;
    }).toList();
  }

  /// Check if a grocery task has all items checked
  Future<bool> _checkGroceryTaskComplete(
    BuildContext context,
    TaskModel task,
  ) async {
    // Only check for grocery tasks
    if (task.category != 'grocery' ||
        task.categoryData?['groceryListId'] == null) {
      return true; // Not a grocery task, allow completion
    }

    try {
      final groceryListId = task.categoryData!['groceryListId'] as String;
      final groceryRepo = ref.read(groceryListRepositoryProvider);
      final items = await groceryRepo.getListItems(groceryListId);

      if (items.isEmpty) {
        // No items, allow completion
        return true;
      }

      // Check if all items are checked
      return items.every((item) => item.checked);
    } catch (e) {
      // If there's an error, allow completion to avoid blocking the user
      return true;
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
    return _buildNewTaskCard(
      context,
      ref,
      task,
      members,
      familyId,
      currentUserId,
    );
  }

  Widget _buildViewModeSelector(BuildContext context) {
    final viewMode = ref.watch(taskViewModeProvider);

    return Container(
      padding: ResponsiveHelper.padding(all: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildViewModeButton(
              context,
              icon: Icons.view_list,
              label: 'List',
              mode: 'list',
              isSelected: viewMode == 'list',
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            _buildViewModeButton(
              context,
              icon: Icons.format_list_bulleted,
              label: 'Simple',
              mode: 'simple_list',
              isSelected: viewMode == 'simple_list',
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            _buildViewModeButton(
              context,
              icon: Icons.grid_view,
              label: 'Grid',
              mode: 'grid',
              isSelected: viewMode == 'grid',
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            _buildViewModeButton(
              context,
              icon: Icons.category,
              label: 'Category',
              mode: 'grouped_category',
              isSelected: viewMode == 'grouped_category',
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            _buildViewModeButton(
              context,
              icon: Icons.person,
              label: 'Assignee',
              mode: 'grouped_assignee',
              isSelected: viewMode == 'grouped_assignee',
            ),
            SizedBox(width: ResponsiveHelper.w(4)),
            _buildViewModeButton(
              context,
              icon: Icons.calendar_today,
              label: 'Due Date',
              mode: 'grouped_due_date',
              isSelected: viewMode == 'grouped_due_date',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewModeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String mode,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        ref.read(taskViewModeProvider.notifier).state = mode;
      },
      borderRadius: ResponsiveHelper.borderRadius(8),
      child: Container(
        padding: ResponsiveHelper.padding(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: ResponsiveHelper.borderRadius(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: ResponsiveHelper.iconSize(16),
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            SizedBox(width: ResponsiveHelper.w(6)),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
    String viewMode,
  ) {
    switch (viewMode) {
      case 'simple_list':
        return _buildSimpleListView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
      case 'grid':
        return _buildGridView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
      case 'grouped_category':
        return _buildGroupedByCategoryView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
      case 'grouped_assignee':
        return _buildGroupedByAssigneeView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
      case 'grouped_due_date':
        return _buildGroupedByDueDateView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
      case 'list':
      default:
        return _buildListView(
          context,
          ref,
          tasks,
          members,
          familyId,
          currentUserId,
        );
    }
  }

  Widget _buildListView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    return Column(
      children: tasks.map((task) {
        return _buildChoreCard(
          context,
          ref,
          task,
          members,
          familyId,
          currentUserId,
        );
      }).toList(),
    );
  }

  /// Simple list view - minimal, clean list format with checkboxes
  Widget _buildSimpleListView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    if (tasks.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      separatorBuilder: (context, index) => Divider(
        height: ResponsiveHelper.h(0.5),
        thickness: ResponsiveHelper.h(0.5),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _buildSimpleListItem(
          context,
          ref,
          task,
          members,
          familyId,
          currentUserId,
        );
      },
    );
  }

  /// Build a simple list item with checkbox, task title, and edit option
  Widget _buildSimpleListItem(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    final taskActions = ref.read(taskActionsProvider);
    final isCompleted = task.status == 'completed';

    return Padding(
      padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Checkbox
          GestureDetector(
            onTap: () {}, // Prevent tap from propagating
            child: SizedBox(
              width: ResponsiveHelper.w(36),
              height: ResponsiveHelper.h(36),
              child: Checkbox(
                value: isCompleted,
                onChanged: (value) async {
                  if (value == true) {
                    final canComplete = await _checkGroceryTaskComplete(
                      context,
                      task,
                    );
                    if (!canComplete) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Please check all items in the grocery list before completing this task.',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        );
                      }
                      return;
                    }
                    final completedTask = await taskActions.completeTask(
                      task.id,
                    );
                    if (context.mounted && completedTask.points > 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Theme.of(context).colorScheme.onPrimary,
                                size: ResponsiveHelper.iconSize(20),
                              ),
                              SizedBox(width: ResponsiveHelper.w(8)),
                              Expanded(
                                child: Text(
                                  '+${completedTask.points} points earned!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } else {
                    await taskActions.updateTask(
                      taskId: task.id,
                      status: 'pending',
                    );
                  }
                  ref.invalidate(familyTasksProvider(familyId));
                  ref.invalidate(tasksDueTodayProvider(familyId));
                  ref.invalidate(familyMembersProvider(familyId));
                },
                activeColor: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(8)),
          // Task title - tappable to navigate
          Expanded(
            child: InkWell(
              onTap: () {
                // Navigate to grocery list if grocery task, else task detail/edit page
                if (task.category == 'grocery' &&
                    task.categoryData?['groceryListId'] != null) {
                  final groceryListId =
                      task.categoryData!['groceryListId'] as String;
                  context.push('/grocery-list/$groceryListId?from=task');
                } else {
                  // Navigate to task detail/edit page
                  final taskJson = TaskModelHelpers.toSupabase(task);
                  context.push(AppConstants.routeEditTask, extra: taskJson);
                }
              },
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: ResponsiveHelper.sp(14),
                ),
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(4)),
          // Edit option
          IconButton(
            icon: Icon(
              Icons.edit,
              size: ResponsiveHelper.iconSize(18),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            onPressed: () {
              // Navigate to grocery list if grocery task, else task detail/edit page
              if (task.category == 'grocery' &&
                  task.categoryData?['groceryListId'] != null) {
                final groceryListId =
                    task.categoryData!['groceryListId'] as String;
                context.push('/grocery-list/$groceryListId?from=task');
              } else {
                // Navigate to task detail/edit page
                final taskJson = TaskModelHelpers.toSupabase(task);
                context.push(AppConstants.routeEditTask, extra: taskJson);
              }
            },
            tooltip: 'Edit task',
            padding: ResponsiveHelper.padding(all: 4),
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        final childAspectRatio = constraints.maxWidth > 600 ? 0.9 : 0.85;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: ResponsiveHelper.w(12),
            mainAxisSpacing: ResponsiveHelper.h(12),
          ),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildGridCard(
              context,
              ref,
              task,
              members,
              familyId,
              currentUserId,
            );
          },
        );
      },
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    final category = TaskCategories.getById(task.category);
    final assignedMember = members.firstWhere(
      (m) => m.uid == task.assignedTo,
      orElse: () => const FamilyMemberModel(
        uid: '',
        displayName: '',
        role: 'member',
        points: 0,
      ),
    );

    return ModernCard(
      onTap: () {
        if (task.category == 'grocery' &&
            task.categoryData?['groceryListId'] != null) {
          context.push(
            '/grocery-list/${task.categoryData!['groceryListId']}?from=task',
          );
        } else {
          final taskJson = TaskModelHelpers.toSupabase(task);
          context.push(AppConstants.routeEditTask, extra: taskJson);
        }
      },
      child: Padding(
        padding: ResponsiveHelper.padding(all: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Category and checkbox row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (category != null)
                  Container(
                    padding: ResponsiveHelper.padding(all: 6),
                    decoration: BoxDecoration(
                      color: category.color.withOpacity(0.1),
                      borderRadius: ResponsiveHelper.borderRadius(6),
                    ),
                    child: Icon(
                      category.icon,
                      size: ResponsiveHelper.iconSize(16),
                      color: category.color,
                    ),
                  ),
                Checkbox(
                  value: task.status == 'completed',
                  onChanged: (value) async {
                    final taskActions = ref.read(taskActionsProvider);
                    if (value == true) {
                      // Check if grocery task has all items checked
                      final canComplete = await _checkGroceryTaskComplete(
                        context,
                        task,
                      );
                      if (!canComplete) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Please check all items in the grocery list before completing this task.',
                              ),
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.error,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        return; // Don't complete the task
                      }
                      final completedTask = await taskActions.completeTask(
                        task.id,
                      );
                      // Show points earned feedback
                      if (context.mounted && completedTask.points > 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                  size: ResponsiveHelper.iconSize(20),
                                ),
                                SizedBox(width: ResponsiveHelper.w(8)),
                                Expanded(
                                  child: Text(
                                    '+${completedTask.points} points earned!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    } else {
                      await taskActions.updateTask(
                        taskId: task.id,
                        status: 'pending',
                      );
                    }
                    ref.invalidate(familyTasksProvider(familyId));
                    ref.invalidate(tasksDueTodayProvider(familyId));
                    ref.invalidate(familyMembersProvider(familyId));
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: ResponsiveHelper.borderRadius(4),
                  ),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            // Task title
            Expanded(
              child: Text(
                task.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: task.status == 'completed'
                      ? TextDecoration.lineThrough
                      : null,
                  color: task.status == 'completed'
                      ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                      : Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            // Points, recurrence, and assignee
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: ResponsiveHelper.padding(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: ResponsiveHelper.borderRadius(6),
                      ),
                      child: Text(
                        '${task.points} pts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Recurrence indicator
                    if (task.categoryData?['recurrenceType'] != null &&
                        task.categoryData!['recurrenceType'] != 'none') ...[
                      SizedBox(width: ResponsiveHelper.w(4)),
                      Icon(
                        Icons.repeat_rounded,
                        size: ResponsiveHelper.iconSize(14),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                if (assignedMember.uid.isNotEmpty)
                  Consumer(
                    builder: (context, ref, child) {
                      final userProfileAsync = ref.watch(
                        userProfileProvider(task.assignedTo),
                      );
                      return userProfileAsync.when(
                        data: (profile) {
                          final avatarUrl =
                              profile?.photoURL ?? assignedMember.photoURL;
                          final name =
                              profile?.displayName ??
                              assignedMember.displayName;
                          return AvatarWidget(
                            avatarPath: avatarUrl,
                            radius: ResponsiveHelper.r(12),
                            displayName: name,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            textColor: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          );
                        },
                        loading: () => AvatarWidget(
                          avatarPath: assignedMember.photoURL,
                          radius: ResponsiveHelper.r(12),
                          displayName: assignedMember.displayName,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                        error: (_, __) => AvatarWidget(
                          avatarPath: assignedMember.photoURL,
                          radius: ResponsiveHelper.r(12),
                          displayName: assignedMember.displayName,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          textColor: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedByCategoryView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    // Group tasks by category
    final groupedTasks = <String, List<TaskModel>>{};
    for (final task in tasks) {
      final category = task.category;
      if (!groupedTasks.containsKey(category)) {
        groupedTasks[category] = [];
      }
      groupedTasks[category]!.add(task);
    }

    // Sort categories by name
    final sortedCategories = groupedTasks.keys.toList()
      ..sort((a, b) {
        final catA = TaskCategories.getById(a);
        final catB = TaskCategories.getById(b);
        return (catA?.name ?? a).compareTo(catB?.name ?? b);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedCategories.map((categoryId) {
        final categoryTasks = groupedTasks[categoryId]!;
        final category = TaskCategories.getById(categoryId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Padding(
              padding: ResponsiveHelper.padding(vertical: 8),
              child: Row(
                children: [
                  if (category != null) ...[
                    Icon(
                      category.icon,
                      size: ResponsiveHelper.iconSize(20),
                      color: category.color,
                    ),
                    SizedBox(width: ResponsiveHelper.w(8)),
                  ],
                  Text(
                    category?.name ?? categoryId.categoryDisplayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: category?.color,
                    ),
                  ),
                  SizedBox(width: ResponsiveHelper.w(8)),
                  Container(
                    padding: ResponsiveHelper.padding(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (category?.color ??
                                  Theme.of(context).colorScheme.primary)
                              .withOpacity(0.1),
                      borderRadius: ResponsiveHelper.borderRadius(8),
                    ),
                    child: Text(
                      '${categoryTasks.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            category?.color ??
                            Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tasks in this category
            ...categoryTasks.map((task) {
              return _buildChoreCard(
                context,
                ref,
                task,
                members,
                familyId,
                currentUserId,
              );
            }),
            SizedBox(height: ResponsiveHelper.h(16)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByAssigneeView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    // Group tasks by assignee
    final groupedTasks = <String, List<TaskModel>>{};
    for (final task in tasks) {
      final assigneeId = task.assignedTo;
      if (!groupedTasks.containsKey(assigneeId)) {
        groupedTasks[assigneeId] = [];
      }
      groupedTasks[assigneeId]!.add(task);
    }

    // Sort by member name
    final sortedAssignees = groupedTasks.keys.toList()
      ..sort((a, b) {
        final memberA = members.firstWhere(
          (m) => m.uid == a,
          orElse: () => const FamilyMemberModel(
            uid: '',
            displayName: 'Unknown',
            role: 'member',
            points: 0,
          ),
        );
        final memberB = members.firstWhere(
          (m) => m.uid == b,
          orElse: () => const FamilyMemberModel(
            uid: '',
            displayName: 'Unknown',
            role: 'member',
            points: 0,
          ),
        );
        return memberA.displayName.compareTo(memberB.displayName);
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedAssignees.map((assigneeId) {
        final assigneeTasks = groupedTasks[assigneeId]!;
        final member = members.firstWhere(
          (m) => m.uid == assigneeId,
          orElse: () => const FamilyMemberModel(
            uid: '',
            displayName: 'Unknown',
            role: 'member',
            points: 0,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Assignee header
            Padding(
              padding: ResponsiveHelper.padding(vertical: 8),
              child: Row(
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final userProfileAsync = ref.watch(
                        userProfileProvider(assigneeId),
                      );
                      final avatarUrl = userProfileAsync.when(
                        data: (profile) => profile?.photoURL ?? member.photoURL,
                        loading: () => member.photoURL,
                        error: (_, __) => member.photoURL,
                      );

                      return AvatarWidget(
                        avatarPath: avatarUrl,
                        radius: ResponsiveHelper.r(16),
                        displayName: member.displayName,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Colors.white,
                      );
                    },
                  ),
                  SizedBox(width: ResponsiveHelper.w(12)),
                  Expanded(
                    child: Text(
                      member.displayName.isNotEmpty
                          ? member.displayName
                          : 'Unassigned',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: ResponsiveHelper.padding(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      borderRadius: ResponsiveHelper.borderRadius(8),
                    ),
                    child: Text(
                      '${assigneeTasks.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tasks for this assignee
            ...assigneeTasks.map((task) {
              return _buildChoreCard(
                context,
                ref,
                task,
                members,
                familyId,
                currentUserId,
              );
            }),
            SizedBox(height: ResponsiveHelper.h(16)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildGroupedByDueDateView(
    BuildContext context,
    WidgetRef ref,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group tasks by due date
    final todayTasks = <TaskModel>[];
    final tomorrowTasks = <TaskModel>[];
    final thisWeekTasks = <TaskModel>[];
    final laterTasks = <TaskModel>[];
    final noDueDateTasks = <TaskModel>[];

    for (final task in tasks) {
      if (task.dueDate == null) {
        noDueDateTasks.add(task);
      } else {
        final due = DateTime(
          task.dueDate!.year,
          task.dueDate!.month,
          task.dueDate!.day,
        );
        final difference = due.difference(today).inDays;

        if (difference < 0) {
          // Overdue - add to today
          todayTasks.add(task);
        } else if (difference == 0) {
          todayTasks.add(task);
        } else if (difference == 1) {
          tomorrowTasks.add(task);
        } else if (difference <= 7) {
          thisWeekTasks.add(task);
        } else {
          laterTasks.add(task);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (todayTasks.isNotEmpty) ...[
          _buildDueDateGroup(
            context,
            ref,
            'Today',
            todayTasks,
            members,
            familyId,
            currentUserId,
            Colors.orange,
          ),
          SizedBox(height: ResponsiveHelper.h(16)),
        ],
        if (tomorrowTasks.isNotEmpty) ...[
          _buildDueDateGroup(
            context,
            ref,
            'Tomorrow',
            tomorrowTasks,
            members,
            familyId,
            currentUserId,
            Colors.blue,
          ),
          SizedBox(height: ResponsiveHelper.h(16)),
        ],
        if (thisWeekTasks.isNotEmpty) ...[
          _buildDueDateGroup(
            context,
            ref,
            'This Week',
            thisWeekTasks,
            members,
            familyId,
            currentUserId,
            Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: ResponsiveHelper.h(16)),
        ],
        if (laterTasks.isNotEmpty) ...[
          _buildDueDateGroup(
            context,
            ref,
            'Later',
            laterTasks,
            members,
            familyId,
            currentUserId,
            Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          SizedBox(height: ResponsiveHelper.h(16)),
        ],
        if (noDueDateTasks.isNotEmpty) ...[
          _buildDueDateGroup(
            context,
            ref,
            'No Due Date',
            noDueDateTasks,
            members,
            familyId,
            currentUserId,
            Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ],
    );
  }

  Widget _buildDueDateGroup(
    BuildContext context,
    WidgetRef ref,
    String title,
    List<TaskModel> tasks,
    List<FamilyMemberModel> members,
    String familyId,
    String? currentUserId,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Due date header
        Padding(
          padding: ResponsiveHelper.padding(vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: ResponsiveHelper.iconSize(18),
                color: color,
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Container(
                padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: ResponsiveHelper.borderRadius(8),
                ),
                child: Text(
                  '${tasks.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tasks in this group
        ...tasks.map((task) {
          return _buildChoreCard(
            context,
            ref,
            task,
            members,
            familyId,
            currentUserId,
          );
        }),
      ],
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
