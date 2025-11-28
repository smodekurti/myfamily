import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/task_model.dart';
import '../../../groceries/presentation/pages/grocery_list_page.dart';
import '../widgets/weather_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    
    // Get tasks for today
    final todayTasks = currentFamily != null
        ? ref.watch(tasksDueTodayProvider(currentFamily.id))
        : const AsyncValue<List<TaskModel>>.data(<TaskModel>[]);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
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
              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: ResponsiveHelper.h(8)),
                
                // Weather Widget
                const WeatherWidget(),
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Today's Summary Section
                Text(
                  'Today\'s Summary',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Summary Cards
                Divider(
                  height: ResponsiveHelper.h(1),
                  thickness: ResponsiveHelper.w(1),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                SizedBox(height: ResponsiveHelper.h(12)),
                todayTasks.when(
                  data: (tasks) {
                    final incompleteTasks = tasks.where((t) => t.status != 'completed').toList();
                    return _buildSummaryCard(
                      context,
                      icon: Icons.task_alt,
                      iconColor: Colors.green,
                      title: 'Tasks Due Today',
                      count: incompleteTasks.length,
                      onTap: () => context.go('${AppConstants.routeTasks}?filter=today'),
                    );
                  },
                  loading: () => _buildSummaryCard(
                    context,
                    icon: Icons.task_alt,
                    iconColor: Colors.green,
                    title: 'Tasks Due Today',
                    count: 0,
                    onTap: () => context.go(AppConstants.routeTasks),
                  ),
                  error: (_, __) => _buildSummaryCard(
                    context,
                    icon: Icons.task_alt,
                    iconColor: Colors.green,
                    title: 'Tasks Due Today',
                    count: 0,
                    onTap: () => context.go(AppConstants.routeTasks),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(12)),
                Divider(
                  height: ResponsiveHelper.h(1),
                  thickness: ResponsiveHelper.w(1),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                SizedBox(height: ResponsiveHelper.h(12)),
                
                // Family Calendar with actual events count
                currentFamily != null
                    ? ref.watch(familyEventsProvider(currentFamily.id)).when(
                        data: (events) {
                          // Count upcoming events (not past events)
                          final now = DateTime.now();
                          final upcomingEvents = events.where((event) {
                            return event.startTime.isAfter(now) || 
                                   event.startTime.isAtSameMomentAs(now);
                          }).toList();
                          return _buildSummaryCard(
                            context,
                            icon: Icons.calendar_today,
                            iconColor: Theme.of(context).colorScheme.secondary,
                            title: 'Family Calendar',
                            count: upcomingEvents.length,
                            onTap: () => context.go(AppConstants.routeCalendar),
                          );
                        },
                        loading: () => _buildSummaryCard(
                          context,
                          icon: Icons.calendar_today,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Family Calendar',
                          count: 0,
                          onTap: () => context.go(AppConstants.routeCalendar),
                        ),
                        error: (_, __) => _buildSummaryCard(
                          context,
                          icon: Icons.calendar_today,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Family Calendar',
                          count: 0,
                          onTap: () => context.go(AppConstants.routeCalendar),
                        ),
                      )
                    : _buildSummaryCard(
                        context,
                        icon: Icons.calendar_today,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        title: 'Family Calendar',
                        count: 0,
                        onTap: () => context.go(AppConstants.routeCalendar),
                      ),
                SizedBox(height: ResponsiveHelper.h(12)),
                Divider(
                  height: ResponsiveHelper.h(1),
                  thickness: ResponsiveHelper.w(1),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                SizedBox(height: ResponsiveHelper.h(12)),
                
                // Family Shopping with actual grocery lists count
                currentFamily != null
                    ? ref.watch(allGroceryListsProvider(currentFamily.id)).when(
                        data: (lists) {
                          return _buildSummaryCard(
                            context,
                            icon: Icons.shopping_cart,
                            iconColor: Theme.of(context).colorScheme.secondary,
                            title: 'Family Shopping',
                            count: lists.length,
                            onTap: () => context.go(AppConstants.routeGroceries),
                          );
                        },
                        loading: () => _buildSummaryCard(
                          context,
                          icon: Icons.shopping_cart,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Family Shopping',
                          count: 0,
                          onTap: () => context.go(AppConstants.routeGroceries),
                        ),
                        error: (_, __) => _buildSummaryCard(
                          context,
                          icon: Icons.shopping_cart,
                          iconColor: Theme.of(context).colorScheme.secondary,
                          title: 'Family Shopping',
                          count: 0,
                          onTap: () => context.go(AppConstants.routeGroceries),
                        ),
                      )
                    : _buildSummaryCard(
                        context,
                        icon: Icons.shopping_cart,
                        iconColor: Theme.of(context).colorScheme.secondary,
                        title: 'Family Shopping',
                        count: 0,
                        onTap: () => context.go(AppConstants.routeGroceries),
                      ),
                SizedBox(height: ResponsiveHelper.h(12)),
                Divider(
                  height: ResponsiveHelper.h(1),
                  thickness: ResponsiveHelper.w(1),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
                
                SizedBox(height: ResponsiveHelper.h(32)),
                
                // Family Info Section
                if (currentFamily != null) ...[
                  Text(
                    'Family Info',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  
                  Card(
                    child: InkWell(
                      onTap: () => context.push(AppConstants.routeFamilySettings),
                      borderRadius: ResponsiveHelper.borderRadius(12),
                      child: Padding(
                        padding: ResponsiveHelper.padding(all: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Family Name (clickable)
                            Row(
                              children: [
                                Icon(
                                  Icons.home,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: ResponsiveHelper.iconSize(24),
                                ),
                                SizedBox(width: ResponsiveHelper.w(12)),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          currentFamily.name,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                        size: ResponsiveHelper.iconSize(20),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            // Address
                            if (currentFamily.address != null) ...[
                              SizedBox(height: ResponsiveHelper.h(12)),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    size: ResponsiveHelper.iconSize(20),
                                  ),
                                  SizedBox(width: ResponsiveHelper.w(12)),
                                  Expanded(
                                    child: Text(
                                      currentFamily.address!,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            
                            // Divider
                            SizedBox(height: ResponsiveHelper.h(12)),
                            Divider(
                              height: ResponsiveHelper.h(1),
                              thickness: ResponsiveHelper.w(1),
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                            ),
                            SizedBox(height: ResponsiveHelper.h(12)),
                            
                            // Family Statistics
                            _buildFamilyStats(context, ref, currentFamily.id),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                
                SizedBox(height: ResponsiveHelper.h(80)), // Space for bottom nav
              ],
            ),
          ),
          ),
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
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: ResponsiveHelper.borderRadius(12),
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Row(
            children: [
              // Icon container
              Container(
                width: ResponsiveHelper.w(48),
                height: ResponsiveHelper.h(48),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // Chevron
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                size: ResponsiveHelper.iconSize(20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyStats(BuildContext context, WidgetRef ref, String familyId) {
    final familyMembers = ref.watch(familyMembersProvider(familyId));
    
    return familyMembers.when(
      data: (members) {
        final memberCount = members.length;
        final totalPoints = members.fold<int>(0, (sum, member) => sum + member.points);
        
        return Row(
          children: [
            // Members Count
            Expanded(
              child: _buildStatItem(
                context,
                icon: Icons.people,
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
                icon: Icons.stars,
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
              icon: Icons.people,
              label: 'Members',
              value: '...',
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(16)),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.stars,
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
              icon: Icons.people,
              label: 'Members',
              value: '0',
              iconColor: Theme.of(context).colorScheme.primary,
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(16)),
          Expanded(
            child: _buildStatItem(
              context,
              icon: Icons.stars,
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
    return Row(
      children: [
        Container(
          width: ResponsiveHelper.w(36),
          height: ResponsiveHelper.h(36),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: ResponsiveHelper.borderRadius(8),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: ResponsiveHelper.iconSize(18),
          ),
        ),
        SizedBox(width: ResponsiveHelper.w(8)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(2)),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
