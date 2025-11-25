import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class FamilySelectionPage extends ConsumerWidget {
  const FamilySelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }
    
    final userFamiliesAsync = ref.watch(userFamiliesProvider(currentUser.id));
    
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Select Family'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();
                if (context.mounted) {
                  context.go(AppConstants.routeWelcome);
                }
              },
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.padding(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // Title
                Text(
                  'Choose Your Family',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                
                Text(
                  'You are part of multiple families. Select which one you want to access.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // Family list
                Expanded(
                  child: userFamiliesAsync.when(
                    data: (families) {
                      if (families.isEmpty) {
                        return Center(
                          child: Text(
                            'No families found',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        itemCount: families.length,
                        separatorBuilder: (context, index) => SizedBox(height: ResponsiveHelper.h(16)),
                        itemBuilder: (context, index) {
                          final family = families[index];
                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Set the selected family
                                ref.read(currentFamilyIdProvider.notifier).state = family.id;
                                
                                // Wait a moment for the state to update
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  if (context.mounted) {
                                    context.go(AppConstants.routeHome);
                                  }
                                });
                              },
                              borderRadius: ResponsiveHelper.borderRadius(12),
                              child: Padding(
                                padding: ResponsiveHelper.padding(all: 20),
                                child: Row(
                                  children: [
                                    // Family icon
                                    Container(
                                      width: ResponsiveHelper.w(60),
                                      height: ResponsiveHelper.h(60),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: ResponsiveHelper.borderRadius(12),
                                      ),
                                      child: Icon(
                                        Icons.family_restroom,
                                        size: ResponsiveHelper.iconSize(30),
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(16)),
                                    
                                    // Family details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            family.name,
                                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: ResponsiveHelper.h(4)),
                                          
                                          // Member count and creator info
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.people,
                                                size: ResponsiveHelper.iconSize(14),
                                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                              ),
                                              SizedBox(width: ResponsiveHelper.w(4)),
                                              Text(
                                                '${family.members.length} member${family.members.length != 1 ? 's' : ''}',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                              ),
                                              if (family.createdBy == currentUser.id) ...[
                                                SizedBox(width: ResponsiveHelper.w(8)),
                                                Container(
                                                  padding: ResponsiveHelper.padding(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                                    borderRadius: ResponsiveHelper.borderRadius(4),
                                                  ),
                                                  child: Text(
                                                    'Creator',
                                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.primary,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          
                                          // Invite code (helps distinguish families)
                                          if (family.inviteCode != null && family.inviteCode!.isNotEmpty) ...[
                                            SizedBox(height: ResponsiveHelper.h(4)),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.vpn_key,
                                                  size: ResponsiveHelper.iconSize(14),
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                SizedBox(width: ResponsiveHelper.w(4)),
                                                Text(
                                                  'Code: ${family.inviteCode}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                    fontFamily: 'monospace',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          
                                          // Creation date (helps distinguish same-named families by same creator)
                                          if (family.createdAt != null) ...[
                                            SizedBox(height: ResponsiveHelper.h(4)),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today,
                                                  size: ResponsiveHelper.iconSize(14),
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                SizedBox(width: ResponsiveHelper.w(4)),
                                                Text(
                                                  'Created ${_formatDate(family.createdAt!)}',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          
                                          // Address
                                          if (family.address != null && family.address!.isNotEmpty) ...[
                                            SizedBox(height: ResponsiveHelper.h(4)),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.location_on,
                                                  size: ResponsiveHelper.iconSize(14),
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                ),
                                                SizedBox(width: ResponsiveHelper.w(4)),
                                                Expanded(
                                                  child: Text(
                                                    family.address!,
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    
                                    // Arrow icon
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: ResponsiveHelper.iconSize(20),
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: ResponsiveHelper.iconSize(48),
                            color: Theme.of(context).colorScheme.error,
                          ),
                          SizedBox(height: ResponsiveHelper.h(16)),
                          Text(
                            'Failed to load families',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          Text(
                            error.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.go(AppConstants.routeCreateFamily),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Family'),
                        style: OutlinedButton.styleFrom(
                          padding: ResponsiveHelper.padding(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppConstants.routeJoinFamily),
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join Family'),
                        style: ElevatedButton.styleFrom(
                          padding: ResponsiveHelper.padding(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    // If created today, show time to distinguish multiple families created same day
    if (difference.inDays == 0) {
      // If created within last hour, show minutes
      if (difference.inMinutes < 60) {
        if (difference.inMinutes < 1) {
          return 'just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'min' : 'mins'} ago';
      }
      // If created today but more than an hour ago, show time
      else {
        return 'today at ${DateFormat('h:mm a').format(date)}';
      }
    }
    // If created yesterday, also show time for better distinction
    else if (difference.inDays == 1) {
      return 'yesterday at ${DateFormat('h:mm a').format(date)}';
    }
    // If created within last week
    else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    // If created within last month
    else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    }
    // If created within last year
    else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
    // If older, show the date
    else {
      return DateFormat('MMM d, y').format(date);
    }
  }
}

