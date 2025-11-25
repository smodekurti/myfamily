import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/family_model.dart';

class LeaderboardPage extends ConsumerStatefulWidget {
  const LeaderboardPage({super.key});

  @override
  ConsumerState<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends ConsumerState<LeaderboardPage> {
  bool _showWeekly = false; // false = all-time, true = weekly

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentFamily == null) {
      return BackgroundWidget(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('Leaderboard'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: const Center(
            child: Text('No family selected'),
          ),
        ),
      );
    }

    final familyMembers = ref.watch(familyMembersProvider(currentFamily.id));

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Leaderboard'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: ResponsiveHelper.padding(horizontal: 16),
              child: Center(
                child: ToggleButtons(
                  isSelected: [!_showWeekly, _showWeekly],
                  onPressed: (index) {
                    setState(() {
                      _showWeekly = index == 1;
                    });
                  },
                  borderRadius: ResponsiveHelper.borderRadius(8),
                  constraints: BoxConstraints(
                    minWidth: ResponsiveHelper.w(80),
                    minHeight: ResponsiveHelper.h(36),
                  ),
                  children: const [
                    Text('All-Time'),
                    Text('Weekly'),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: familyMembers.when(
            data: (members) {
              if (members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_outlined,
                        size: ResponsiveHelper.iconSize(80),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: ResponsiveHelper.h(24)),
                      Text(
                        'No members yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Sort members by points (descending)
              final sortedMembers = List<FamilyMemberModel>.from(members)
                ..sort((a, b) => b.points.compareTo(a.points));

              return SingleChildScrollView(
                padding: ResponsiveHelper.padding(all: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      _showWeekly ? 'Weekly Leaderboard' : 'All-Time Leaderboard',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(8)),
                    Text(
                      'Family members ranked by points',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(24)),
                    
                    // Leaderboard list
                    ...sortedMembers.asMap().entries.map((entry) {
                      final index = entry.key;
                      final member = entry.value;
                      final isCurrentUser = currentUser?.id == member.uid;
                      
                      return _buildLeaderboardItem(
                        context,
                        rank: index + 1,
                        member: member,
                        isCurrentUser: isCurrentUser,
                      );
                    }),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Error loading leaderboard: $error'),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardItem(
    BuildContext context, {
    required int rank,
    required FamilyMemberModel member,
    required bool isCurrentUser,
  }) {
    // Medal icons for top 3
    IconData? medalIcon;
    Color? medalColor;
    if (rank == 1) {
      medalIcon = Icons.emoji_events;
      medalColor = Colors.amber;
    } else if (rank == 2) {
      medalIcon = Icons.workspace_premium;
      medalColor = Colors.grey.shade400;
    } else if (rank == 3) {
      medalIcon = Icons.military_tech;
      medalColor = Colors.brown.shade300;
    }

    return Card(
      margin: ResponsiveHelper.padding(bottom: 12),
      color: isCurrentUser
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
        side: isCurrentUser
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: ResponsiveHelper.w(8)),
            if (medalIcon != null)
              Icon(
                medalIcon,
                color: medalColor,
                size: ResponsiveHelper.iconSize(28),
              )
            else
              Container(
                width: ResponsiveHelper.w(32),
                height: ResponsiveHelper.h(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            SizedBox(width: ResponsiveHelper.w(12)),
            CircleAvatar(
              radius: ResponsiveHelper.w(24),
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              backgroundImage: member.photoURL != null
                  ? NetworkImage(member.photoURL!)
                  : null,
              child: member.photoURL == null
                  ? Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: ResponsiveHelper.borderRadius(8),
                ),
                child: Text(
                  'You',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${member.points} points',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(
          Icons.star,
          color: Theme.of(context).colorScheme.primary,
          size: ResponsiveHelper.iconSize(24),
        ),
      ),
    );
  }
}

