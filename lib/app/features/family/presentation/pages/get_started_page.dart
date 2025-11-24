import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class GetStartedPage extends ConsumerWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Get Started'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();
                if (context.mounted) {
                  context.go(AppConstants.routeAuth);
                }
              },
              tooltip: 'Sign Out',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.padding(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Welcome icon
                Container(
                  width: ResponsiveHelper.w(100),
                  height: ResponsiveHelper.h(100),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.family_restroom,
                    size: ResponsiveHelper.iconSize(50),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Welcome message
                Text(
                  'Welcome${currentUser != null ? ', ${currentUser.email?.split('@').first ?? 'User'}' : ''}!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveHelper.h(12)),
                
                Text(
                  'Let\'s get you set up with your family',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveHelper.h(32)),
                
                // Create Family Card
                _buildOptionCard(
                  context,
                  icon: Icons.add_circle_outline,
                  title: 'Create a Family',
                  description: 'Start your own family and invite members to join',
                  buttonText: 'Create Family',
                  onTap: () => context.go(AppConstants.routeCreateFamily),
                  isPrimary: true,
                ),
                
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Divider with "OR"
                Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
                    Padding(
                      padding: ResponsiveHelper.padding(horizontal: 12),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3))),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.h(16)),
                
                // Join Family Card
                _buildOptionCard(
                  context,
                  icon: Icons.group_add,
                  title: 'Join a Family',
                  description: 'Use an invite code to join an existing family',
                  buttonText: 'Join Family',
                  onTap: () => context.go(AppConstants.routeJoinFamily),
                  isPrimary: false,
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
        side: isPrimary
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                width: ResponsiveHelper.w(2),
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: ResponsiveHelper.padding(all: 20),
        child: Column(
          children: [
            // Icon
            Container(
              width: ResponsiveHelper.w(70),
              height: ResponsiveHelper.h(70),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: ResponsiveHelper.borderRadius(16),
              ),
              child: Icon(
                icon,
                size: ResponsiveHelper.iconSize(35),
                color: isPrimary
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.secondary,
              ),
            ),
            
            SizedBox(height: ResponsiveHelper.h(16)),
            
            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveHelper.h(8)),
            
            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ResponsiveHelper.h(20)),
            
            // Button
            SizedBox(
              width: double.infinity,
              height: ResponsiveHelper.buttonHeight(44),
              child: isPrimary
                  ? ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      child: Text(buttonText),
                    )
                  : OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      child: Text(buttonText),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

