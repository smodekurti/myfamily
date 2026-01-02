import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/constants/app_constants.dart';

class FamilySetupPage extends StatelessWidget {
  const FamilySetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppConstants.routeFamilySelection),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.padding(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: ResponsiveHelper.h(60)),
                
                // App title
                Text(
                  'Family Hub',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // Illustration
                Container(
                  width: ResponsiveHelper.w(200),
                  height: ResponsiveHelper.h(200),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: ResponsiveHelper.borderRadius(100),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.home,
                        size: ResponsiveHelper.iconSize(80),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      Positioned(
                        top: ResponsiveHelper.h(40),
                        right: ResponsiveHelper.w(40),
                        child: Container(
                          width: ResponsiveHelper.w(24),
                          height: ResponsiveHelper.h(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check,
                            size: ResponsiveHelper.iconSize(16),
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // Welcome text
                Text(
                  'Set up your family',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                
                Text(
                  'Create a new family or join an existing one to start coordinating tasks, managing shopping, and staying connected.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Primary action - Get Started
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveHelper.buttonHeight(56),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeCreateFamily),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: ResponsiveHelper.h(24)),
                
                // Secondary actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppConstants.routeCreateFamily),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                        child: Text(
                          'Create a Family',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(16)),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppConstants.routeJoinFamily),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                        child: Text(
                          'Join a Family',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveHelper.h(40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
