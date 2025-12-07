import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/modern_card.dart';
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../data/models/task_model.dart';
import '../../../groceries/presentation/pages/grocery_list_page.dart';
import '../widgets/weather_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);

    // Get tasks for today
    final todayTasks = currentFamily != null
        ? ref.watch(tasksDueTodayProvider(currentFamily.id))
        : const AsyncValue<List<TaskModel>>.data(<TaskModel>[]);

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Family Wall',
              subtitle: 'Here\'s what\'s happening today',
              leading: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              actions: [
                Padding(
                  padding: ResponsiveHelper.padding(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push(AppConstants.routeProfile),
                    child: AvatarWidget(
                      avatarPath: currentUser?.avatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName:
                          currentUser?.userMetadata?['full_name'] as String? ??
                          'User',
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh from server when user pulls to refresh
                  final currentFamily = ref.read(currentFamilyProvider);
                  if (currentFamily != null) {
                    ref.invalidate(tasksDueTodayProvider(currentFamily.id));
                    ref.invalidate(familyEventsProvider(currentFamily.id));
                    ref.invalidate(familyMembersProvider(currentFamily.id));
                  }
                  // Wait a moment for the stream to fetch new data
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: ResponsiveHelper.padding(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Weather Widget
                        const WeatherWidget(),
                        SizedBox(height: ResponsiveHelper.h(32)),

                        // Today's Summary Section
                        Text(
                          'Today\'s Summary',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),

                        // Summary Cards
                        todayTasks.when(
                          data: (tasks) {
                            final incompleteTasks = tasks
                                .where((t) => t.status != 'completed')
                                .toList();
                            return _buildSummaryCard(
                              context,
                              icon: Icons.task_alt_rounded,
                              iconColor: Colors.green,
                              title: 'Tasks Due Today',
                              count: incompleteTasks.length,
                              onTap: () => context.go(
                                '${AppConstants.routeTasks}?filter=today',
                              ),
                            );
                          },
                          loading: () => _buildSummaryCard(
                            context,
                            icon: Icons.task_alt_rounded,
                            iconColor: Colors.green,
                            title: 'Tasks Due Today',
                            count: 0,
                            onTap: () => context.go(AppConstants.routeTasks),
                          ),
                          error: (_, __) => _buildSummaryCard(
                            context,
                            icon: Icons.task_alt_rounded,
                            iconColor: Colors.green,
                            title: 'Tasks Due Today',
                            count: 0,
                            onTap: () => context.go(AppConstants.routeTasks),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(12)),

                        // Family Calendar with actual events count
                        currentFamily != null
                            ? ref
                                  .watch(familyEventsProvider(currentFamily.id))
                                  .when(
                                    data: (events) {
                                      // Count upcoming events (not past events)
                                      final now = DateTime.now();
                                      final upcomingEvents = events.where((
                                        event,
                                      ) {
                                        return event.startTime.isAfter(now) ||
                                            event.startTime.isAtSameMomentAs(
                                              now,
                                            );
                                      }).toList();
                                      return _buildSummaryCard(
                                        context,
                                        icon: Icons.calendar_month_rounded,
                                        iconColor: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                        title: 'Family Calendar',
                                        count: upcomingEvents.length,
                                        onTap: () => context.go(
                                          AppConstants.routeCalendar,
                                        ),
                                      );
                                    },
                                    loading: () => _buildSummaryCard(
                                      context,
                                      icon: Icons.calendar_month_rounded,
                                      iconColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      title: 'Family Calendar',
                                      count: 0,
                                      onTap: () => context.go(
                                        AppConstants.routeCalendar,
                                      ),
                                    ),
                                    error: (_, __) => _buildSummaryCard(
                                      context,
                                      icon: Icons.calendar_month_rounded,
                                      iconColor: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      title: 'Family Calendar',
                                      count: 0,
                                      onTap: () => context.go(
                                        AppConstants.routeCalendar,
                                      ),
                                    ),
                                  )
                            : _buildSummaryCard(
                                context,
                                icon: Icons.calendar_month_rounded,
                                iconColor: Theme.of(
                                  context,
                                ).colorScheme.secondary,
                                title: 'Family Calendar',
                                count: 0,
                                onTap: () =>
                                    context.go(AppConstants.routeCalendar),
                              ),
                        SizedBox(height: ResponsiveHelper.h(12)),

                        // Family Shopping with actual grocery lists count
                        currentFamily != null
                            ? ref
                                  .watch(
                                    allGroceryListsProvider(currentFamily.id),
                                  )
                                  .when(
                                    data: (lists) {
                                      return _buildSummaryCard(
                                        context,
                                        icon: Icons.shopping_bag_rounded,
                                        iconColor: Colors.orange,
                                        title: 'Shopping Lists',
                                        count: lists.length,
                                        onTap: () => context.go(
                                          AppConstants.routeGroceries,
                                        ),
                                      );
                                    },
                                    loading: () => _buildSummaryCard(
                                      context,
                                      icon: Icons.shopping_bag_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Shopping Lists',
                                      count: 0,
                                      onTap: () => context.go(
                                        AppConstants.routeGroceries,
                                      ),
                                    ),
                                    error: (_, __) => _buildSummaryCard(
                                      context,
                                      icon: Icons.shopping_bag_rounded,
                                      iconColor: Colors.orange,
                                      title: 'Shopping Lists',
                                      count: 0,
                                      onTap: () => context.go(
                                        AppConstants.routeGroceries,
                                      ),
                                    ),
                                  )
                            : _buildSummaryCard(
                                context,
                                icon: Icons.shopping_bag_rounded,
                                iconColor: Colors.orange,
                                title: 'Shopping Lists',
                                count: 0,
                                onTap: () =>
                                    context.go(AppConstants.routeGroceries),
                              ),

                        SizedBox(height: ResponsiveHelper.h(32)),

                        // Leaderboard Card
                        ModernCard(
                          onTap: () =>
                              context.push(AppConstants.routeLeaderboard),
                          child: Row(
                            children: [
                              // Icon container
                              Container(
                                width: ResponsiveHelper.w(48),
                                height: ResponsiveHelper.h(48),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.1),
                                  borderRadius: ResponsiveHelper.borderRadius(
                                    12,
                                  ),
                                ),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.amber,
                                  size: ResponsiveHelper.iconSize(24),
                                ),
                              ),
                              SizedBox(width: ResponsiveHelper.w(16)),
                              // Text content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Leaderboard',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    SizedBox(height: ResponsiveHelper.h(4)),
                                    Text(
                                      'View family rankings',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              // Chevron
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                                size: ResponsiveHelper.iconSize(24),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: ResponsiveHelper.h(32)),

                        // Family Info Section
                        if (currentFamily != null) ...[
                          Text(
                            'Family Info',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          SizedBox(height: ResponsiveHelper.h(16)),

                          ModernCard(
                            onTap: () =>
                                context.push(AppConstants.routeFamilySettings),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Family Name (clickable)
                                Row(
                                  children: [
                                    Container(
                                      padding: ResponsiveHelper.padding(all: 8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.home_rounded,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        size: ResponsiveHelper.iconSize(20),
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(12)),
                                    Expanded(
                                      child: Text(
                                        currentFamily.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                      size: ResponsiveHelper.iconSize(20),
                                    ),
                                  ],
                                ),

                                // Address
                                if (currentFamily.address != null) ...[
                                  SizedBox(height: ResponsiveHelper.h(12)),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                        size: ResponsiveHelper.iconSize(16),
                                      ),
                                      SizedBox(width: ResponsiveHelper.w(8)),
                                      Expanded(
                                        child: Text(
                                          currentFamily.address!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],

                                // Divider
                                Padding(
                                  padding: ResponsiveHelper.padding(
                                    vertical: 16,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.1),
                                  ),
                                ),

                                // Family Statistics
                                _buildFamilyStats(
                                  context,
                                  ref,
                                  currentFamily.id,
                                ),
                              ],
                            ),
                          ),
                        ],

                        SizedBox(
                          height: ResponsiveHelper.h(100),
                        ), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    required VoidCallback onTap,
  }) {
    return ModernCard(
      onTap: onTap,
      child: Row(
        children: [
          // Icon container
          Container(
            width: ResponsiveHelper.w(48),
            height: ResponsiveHelper.h(48),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: ResponsiveHelper.borderRadius(12),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: ResponsiveHelper.iconSize(24),
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(16)),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(4)),
                Text(
                  '$count ${count == 1 ? 'item' : 'items'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          // Chevron
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            size: ResponsiveHelper.iconSize(20),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyStats(
    BuildContext context,
    WidgetRef ref,
    String familyId,
  ) {
    final familyMembers = ref.watch(familyMembersProvider(familyId));

    return familyMembers.when(
      data: (members) {
        final memberCount = members.length;
        final totalPoints = members.fold<int>(
          0,
          (sum, member) => sum + member.points,
        );

        return Row(
          children: [
            // Members Count
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.people_outline_rounded,
                label: 'Members',
                value: memberCount.toString(),
                iconColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(16)),
            // Total Points
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.stars_rounded,
                label: 'Points',
                value: totalPoints.toString(),
                iconColor: Colors.amber,
              ),
            ),
          ],
        );
      },
      loading: () => Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.people_outline_rounded,
              label: 'Members',
              value: '...',
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(16)),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.stars_rounded,
              label: 'Points',
              value: '...',
              iconColor: Colors.amber,
            ),
          ),
        ],
      ),
      error: (_, __) => Row(
        children: [
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.people_outline_rounded,
              label: 'Members',
              value: '0',
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(16)),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.stars_rounded,
              label: 'Points',
              value: '0',
              iconColor: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: ResponsiveHelper.padding(all: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: Row(
        children: [
          Container(
            width: ResponsiveHelper.w(32),
            height: ResponsiveHelper.h(32),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: ResponsiveHelper.borderRadius(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: ResponsiveHelper.iconSize(18),
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
