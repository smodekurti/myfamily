import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<Color?> _colorAnimation1;
  late Animation<Color?> _colorAnimation2;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppConstants.splashAnimationDuration,
      vsync: this,
    );

    // Staggered Animations

    // 1. Logo Scale & Fade (Starts immediately)
    _logoScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // 2. Text Slide & Fade (Starts after logo)
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    // Breathing Gradient Animation (Loops)
    _colorAnimation1 =
        ColorTween(
          begin: const Color(0xFF1E5FA8), // Primary Blue
          end: const Color(0xFF6A1B9A), // Purple accent
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 1.0, curve: Curves.linear),
          ),
        );

    _colorAnimation2 =
        ColorTween(
          begin: const Color(0xFF1976D2),
          end: const Color(0xFF8E24AA),
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.0, 1.0, curve: Curves.linear),
          ),
        );

    _animationController.forward();
    _animationController.repeat(reverse: true); // For the gradient breathing

    _navigateToNext();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToNext() {
    // Wait for the main entrance animations to complete + buffer
    Future.delayed(AppConstants.splashDisplayDuration, () {
      if (mounted) {
        final routerState = ref.read(routerStateProvider);

        switch (routerState) {
          case RouterState.unauthenticated:
            context.go(AppConstants.routeAuth);
            break;
          case RouterState.loading:
            break;
          case RouterState.authenticatedWithoutFamily:
            context.go(AppConstants.routeGetStarted);
            break;
          case RouterState.authenticatedWithFamily:
            context.go(AppConstants.routeFamilySelection);
            break;
          case RouterState.biometricLocked:
            context.go('/bio-auth');
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _colorAnimation1.value ?? Theme.of(context).primaryColor,
                  Theme.of(context).scaffoldBackgroundColor,
                  _colorAnimation2.value?.withValues(alpha: 0.3) ??
                      Colors.blue.withValues(alpha: 0.3),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  FadeTransition(
                    opacity: _logoFadeAnimation,
                    child: ScaleTransition(
                      scale: _logoScaleAnimation,
                      child: LogoWidget(
                        size: ResponsiveHelper.w(160),
                        showText: true,
                        isAnimated: false, // We control animation here
                      ),
                    ),
                  ),

                  SizedBox(height: ResponsiveHelper.h(24)),

                  // Slogan
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textFadeAnimation,
                      child: Padding(
                        padding: ResponsiveHelper.padding(horizontal: 40),
                        child: Text(
                          'Connecting families,\none task at a time',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
