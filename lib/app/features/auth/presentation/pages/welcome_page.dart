import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/logo_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/constants/app_constants.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: ResponsiveHelper.padding(horizontal: 24),
            child: Column(
              children: [
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // App logo
                Center(
                  child: LogoWidget(
                    size: ResponsiveHelper.w(160),
                    showText: true,
                    isAnimated: true,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(40)),
                
                // Welcome text
                Text(
                  'Welcome to Family Hub',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                
                Text(
                  'Make day-to-day coordination effortless with tasks, calendar, shopping, finances, and habits—all gamified to reduce friction.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const Spacer(),
                
                // Get Started button
                SizedBox(
                  width: double.infinity,
                  height: ResponsiveHelper.buttonHeight(56),
                  child: ElevatedButton(
                    onPressed: () => context.go(AppConstants.routeAuth),
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
