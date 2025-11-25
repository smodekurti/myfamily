import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/user_extensions.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final currentFamily = ref.watch(currentFamilyProvider);
    final userFamilies = currentUser != null 
        ? ref.watch(userFamiliesProvider(currentUser.id))
        : const AsyncValue.data([]);
    
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // App bar is provided by MainShell
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.padding(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: ResponsiveHelper.h(32)),
                
                // Profile header
                Card(
                  child: Padding(
                    padding: ResponsiveHelper.padding(all: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile picture
                        CircleAvatar(
                          radius: ResponsiveHelper.r(40),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: currentUser?.avatarUrl != null
                              ? NetworkImage(currentUser!.avatarUrl!)
                              : null,
                          child: currentUser?.avatarUrl == null
                              ? Icon(
                                  Icons.person,
                                  size: ResponsiveHelper.iconSize(40),
                                  color: Theme.of(context).colorScheme.onPrimary,
                                )
                              : null,
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                        
                        // User name
                        Text(
                          currentUser?.displayNameOrEmail ?? 'User',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(8)),
                        
                        // User email
                        Text(
                          currentUser?.email ?? 'No email',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(12)),
                        
                        // Family information
                        if (currentFamily != null) ...[
                          // Family name
                          Container(
                            padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: ResponsiveHelper.borderRadius(20),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: ResponsiveHelper.w(1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom,
                                  size: ResponsiveHelper.iconSize(16),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: ResponsiveHelper.w(8)),
                                Text(
                                  currentFamily.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          
                          // Adult Invite Code
                          ...[
                            Container(
                              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                borderRadius: ResponsiveHelper.borderRadius(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  width: ResponsiveHelper.w(1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person,
                                    size: ResponsiveHelper.iconSize(16),
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  SizedBox(width: ResponsiveHelper.w(8)),
                                  if (currentFamily.inviteCode != null) ...[
                                    Text(
                                      'Adult Code: ${currentFamily.inviteCode}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(8)),
                                    GestureDetector(
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(text: currentFamily.inviteCode!));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Adult invite code copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: ResponsiveHelper.iconSize(16),
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Adult Code: Not Set',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(8)),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final generateCodeAsync = ref.watch(generateInviteCodeProvider(currentFamily.id));
                                        
                                        return generateCodeAsync.when(
                                          data: (code) {
                                            if (code != null) {
                                              // Code generated successfully, refresh the page
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                ref.invalidate(familyProvider(currentFamily.id));
                                              });
                                              return Icon(
                                                Icons.check,
                                                size: ResponsiveHelper.iconSize(16),
                                                color: Theme.of(context).colorScheme.primary,
                                              );
                                            }
                                            return GestureDetector(
                                              onTap: () {
                                                ref.invalidate(generateInviteCodeProvider(currentFamily.id));
                                              },
                                              child: Icon(
                                                Icons.refresh,
                                                size: ResponsiveHelper.iconSize(16),
                                                color: Theme.of(context).colorScheme.secondary,
                                              ),
                                            );
                                          },
                                          loading: () => SizedBox(
                                            width: ResponsiveHelper.iconSize(16),
                                            height: ResponsiveHelper.iconSize(16),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).colorScheme.secondary,
                                              ),
                                            ),
                                          ),
                                          error: (error, stack) => GestureDetector(
                                            onTap: () {
                                              ref.invalidate(generateInviteCodeProvider(currentFamily.id));
                                            },
                                            child: Icon(
                                              Icons.error_outline,
                                              size: ResponsiveHelper.iconSize(16),
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          
                          SizedBox(height: ResponsiveHelper.h(8)),
                          
                          // Child Invite Code
                          ...[
                            Container(
                              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                borderRadius: ResponsiveHelper.borderRadius(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                                  width: ResponsiveHelper.w(1),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.child_care,
                                    size: ResponsiveHelper.iconSize(16),
                                    color: Theme.of(context).colorScheme.tertiary,
                                  ),
                                  SizedBox(width: ResponsiveHelper.w(8)),
                                  if (currentFamily.childInviteCode != null) ...[
                                    Text(
                                      'Child Code: ${currentFamily.childInviteCode}',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.tertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(8)),
                                    GestureDetector(
                                      onTap: () async {
                                        await Clipboard.setData(ClipboardData(text: currentFamily.childInviteCode!));
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Child invite code copied to clipboard'),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      child: Icon(
                                        Icons.copy,
                                        size: ResponsiveHelper.iconSize(16),
                                        color: Theme.of(context).colorScheme.tertiary,
                                      ),
                                    ),
                                  ] else ...[
                                    Text(
                                      'Child Code: Not Set',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.tertiary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.w(8)),
                                    Consumer(
                                      builder: (context, ref, child) {
                                        final generateCodeAsync = ref.watch(generateChildInviteCodeProvider(currentFamily.id));
                                        
                                        return generateCodeAsync.when(
                                          data: (code) {
                                            if (code != null) {
                                              // Code generated successfully, refresh the page
                                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                                ref.invalidate(familyProvider(currentFamily.id));
                                              });
                                              return Icon(
                                                Icons.check,
                                                size: ResponsiveHelper.iconSize(16),
                                                color: Theme.of(context).colorScheme.primary,
                                              );
                                            }
                                            return GestureDetector(
                                              onTap: () {
                                                ref.invalidate(generateChildInviteCodeProvider(currentFamily.id));
                                              },
                                              child: Icon(
                                                Icons.refresh,
                                                size: ResponsiveHelper.iconSize(16),
                                                color: Theme.of(context).colorScheme.tertiary,
                                              ),
                                            );
                                          },
                                          loading: () => SizedBox(
                                            width: ResponsiveHelper.iconSize(16),
                                            height: ResponsiveHelper.iconSize(16),
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Theme.of(context).colorScheme.tertiary,
                                              ),
                                            ),
                                          ),
                                          error: (error, stack) => GestureDetector(
                                            onTap: () {
                                              ref.invalidate(generateChildInviteCodeProvider(currentFamily.id));
                                            },
                                            child: Icon(
                                              Icons.error_outline,
                                              size: ResponsiveHelper.iconSize(16),
                                              color: Theme.of(context).colorScheme.error,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          // Show loading or no family state
                          userFamilies.when(
                            data: (families) {
                              if (families.isEmpty) {
                                return Container(
                                  padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: ResponsiveHelper.borderRadius(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.family_restroom_outlined,
                                        size: ResponsiveHelper.iconSize(16),
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: ResponsiveHelper.w(8)),
                                      Text(
                                        'No family',
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => Container(
                              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: ResponsiveHelper.borderRadius(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: ResponsiveHelper.iconSize(16),
                                    height: ResponsiveHelper.iconSize(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveHelper.w(8)),
                                  Text(
                                    'Loading...',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            error: (error, stack) => Container(
                              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.errorContainer,
                                borderRadius: ResponsiveHelper.borderRadius(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: ResponsiveHelper.iconSize(16),
                                    color: Theme.of(context).colorScheme.onErrorContainer,
                                  ),
                                  SizedBox(width: ResponsiveHelper.w(8)),
                                  Text(
                                    'Error loading family',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Profile options
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.w(400), // Max width for better centering
                    ),
                    child: Column(
                      children: [
                        _buildProfileOption(
                          context,
                          icon: Icons.edit,
                          title: 'Edit Profile',
                          onTap: () {
                            context.push(AppConstants.routeEditProfile);
                          },
                        ),
                        
                        _buildProfileOption(
                          context,
                          icon: Icons.family_restroom,
                          title: 'Family Settings',
                          onTap: () {
                            context.push(AppConstants.routeFamilySettings);
                          },
                        ),
                        
                        _buildProfileOption(
                          context,
                          icon: Icons.settings,
                          title: 'Settings',
                          onTap: () {
                            context.push(AppConstants.routeSettings);
                          },
                        ),
                        
                        _buildProfileOption(
                          context,
                          icon: Icons.help,
                          title: 'Help & Support',
                          onTap: () {
                            context.push(AppConstants.routeHelp);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(32)),
                
                // Sign out button
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.w(400), // Max width for better centering
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            final authRepo = ref.read(authRepositoryProvider);
                            await authRepo.signOut();
                            if (context.mounted) {
                              context.go(AppConstants.routeWelcome);
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Sign out failed: ${e.toString()}'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                          side: BorderSide(color: Theme.of(context).colorScheme.error),
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.h(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: ResponsiveHelper.borderRadius(12),
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.w(40),
                height: ResponsiveHelper.h(40),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: ResponsiveHelper.borderRadius(20),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveHelper.iconSize(20),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(16)),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: ResponsiveHelper.iconSize(16),
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
