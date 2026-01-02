import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/achievement_model.dart';
import '../../../../common/widgets/modern_header.dart';

class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);

    if (currentUser == null || currentFamily == null) {
      return BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              ModernHeader(
                title: 'Achievements',
                leading: IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              const Expanded(
                child: Center(
                  child: Text('Please select a family to view achievements'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final achievementsAsync = ref.watch(
      userAchievementsProvider((currentUser.id, currentFamily.id)),
    );

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Achievements',
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
                      avatarPath: currentUser.avatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName:
                          currentUser.userMetadata?['full_name'] as String? ??
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
              child: achievementsAsync.when(
                data: (unlockedAchievements) {
                  // Create a map of unlocked achievement IDs
                  final unlockedIds = unlockedAchievements
                      .map((a) => a.achievementId)
                      .toSet();

                  return ListView(
                    padding: ResponsiveHelper.padding(all: 16),
                    children: [
                      // Header
                      Text(
                        'Your Achievements',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      Text(
                        '${unlockedAchievements.length} of ${AchievementType.values.length} unlocked',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(24)),

                      // Achievement grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: ResponsiveHelper.w(12),
                          mainAxisSpacing: ResponsiveHelper.h(12),
                        ),
                        itemCount: AchievementType.values.length,
                        itemBuilder: (context, index) {
                          final achievement = AchievementType.values[index];
                          final isUnlocked = unlockedIds.contains(
                            achievement.id,
                          );
                          AchievementModel? unlockedAchievement;
                          try {
                            unlockedAchievement = unlockedAchievements
                                .firstWhere(
                                  (a) => a.achievementId == achievement.id,
                                );
                          } catch (e) {
                            unlockedAchievement = null;
                          }

                          return _buildAchievementCard(
                            context,
                            achievement,
                            isUnlocked,
                            unlockedAchievement?.unlockedAt,
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: ResponsiveHelper.iconSize(64),
                        color: Theme.of(context).colorScheme.error,
                      ),
                      SizedBox(height: ResponsiveHelper.h(16)),
                      Text(
                        'Error loading achievements',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      TextButton(
                        onPressed: () {
                          ref.invalidate(
                            userAchievementsProvider((
                              currentUser.id,
                              currentFamily.id,
                            )),
                          );
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(
    BuildContext context,
    AchievementType achievement,
    bool isUnlocked,
    DateTime? unlockedAt,
  ) {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: ResponsiveHelper.borderRadius(12),
          color: isUnlocked
              ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                achievement.icon,
                size: ResponsiveHelper.iconSize(48),
                color: isUnlocked
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              SizedBox(height: ResponsiveHelper.h(12)),

              // Name
              Text(
                achievement.name,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: ResponsiveHelper.h(4)),

              // Description
              Text(
                achievement.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isUnlocked
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: ResponsiveHelper.sp(10),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Unlocked date
              if (isUnlocked && unlockedAt != null) ...[
                SizedBox(height: ResponsiveHelper.h(8)),
                Text(
                  'Unlocked ${DateFormat('MMM d').format(unlockedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: ResponsiveHelper.sp(9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
