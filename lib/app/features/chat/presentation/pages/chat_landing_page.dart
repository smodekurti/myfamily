import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';

import '../../../../data/models/family_model.dart';

class ChatLandingPage extends ConsumerWidget {
  const ChatLandingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final membersAsync = currentFamily != null
        ? ref.watch(familyMembersProvider(currentFamily.id))
        : const AsyncValue.loading();

    if (currentFamily == null || currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Access Chats',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // FAMILY ROOM
                  _buildChatTile(
                    context,
                    title: 'Family Room',
                    subtitle: 'General chat for everyone',
                    icon: Icons.people_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    onTap: () {
                      context.pushNamed(
                        'chat-details',
                        pathParameters: {
                          'channelId': 'general',
                          'channelType': 'family',
                        },
                        queryParameters: {'title': 'Family Room'},
                      );
                    },
                  ),

                  const SizedBox(height: 24),
                  Text(
                    'Direct Messages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // FAMILY MEMBERS LIST
                  membersAsync.when(
                    data: (members) {
                      // Filter out current user
                      final otherMembers = members
                          .where((m) => m.uid != currentUser.id)
                          .toList();

                      if (otherMembers.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'No other family members yet.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: otherMembers.map<Widget>((member) {
                          return _buildMemberTile(
                            context,
                            member,
                            currentUser.id,
                          );
                        }).toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
            // Bottom spacer for floating nav bar
            SizedBox(height: ResponsiveHelper.h(80)),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    FamilyMemberModel member,
    String currentUserId,
  ) {
    // Generate DM Channel ID: dm_minId_maxId
    final ids = [currentUserId, member.uid]..sort();
    final channelId = 'dm_${ids[0]}_${ids[1]}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: AvatarWidget(
          avatarPath: member.photoURL,
          displayName: member.displayName,
          radius: 20,
          backgroundColor: Theme.of(context).colorScheme.secondary,
          textColor: Theme.of(context).colorScheme.onSecondary,
        ),
        title: Text(
          member.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          member.role.toUpperCase(),
          style: const TextStyle(fontSize: 12),
        ),
        onTap: () {
          context.pushNamed(
            'chat-details',
            pathParameters: {'channelId': channelId, 'channelType': 'dm'},
            queryParameters: {
              'title': member.displayName, // Pass name to display in header
            },
          );
        },
      ),
    );
  }
}
