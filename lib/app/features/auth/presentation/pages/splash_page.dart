import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/logo_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.splashAnimationDuration,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: AppConstants.fadeAnimationStart,
      end: AppConstants.fadeAnimationEndValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        AppConstants.fadeAnimationStart,
        AppConstants.fadeAnimationEnd,
        curve: Curves.easeIn,
      ),
    ));

    _scaleAnimation = Tween<double>(
      begin: AppConstants.scaleAnimationBegin,
      end: AppConstants.scaleAnimationEndValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(
        AppConstants.scaleAnimationStart,
        AppConstants.scaleAnimationEnd,
        curve: Curves.elasticOut,
      ),
    ));

    _animationController.forward();
    _navigateToNext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    Future.delayed(AppConstants.splashDisplayDuration, () {
      if (mounted) {
        // Check router state and navigate accordingly
        final routerState = ref.read(routerStateProvider);
        
        switch (routerState) {
          case RouterState.unauthenticated:
            context.go(AppConstants.routeAuth);
            break;
          case RouterState.loading:
            // Still loading, stay on splash
            break;
          case RouterState.authenticatedWithoutFamily:
            context.go(AppConstants.routeGetStarted);
            break;
          case RouterState.authenticatedWithFamily:
            context.go(AppConstants.routeFamilySelection);
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      showGradient: true,
      gradientColors: [
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        Theme.of(context).colorScheme.surface,
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // App logo with animation
                      LogoWidget(
                        size: ResponsiveHelper.w(150),
                        showText: true,
                        isAnimated: true,
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      
                      // Subtitle
                      Text(
                        'Connecting families, one task at a time',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
