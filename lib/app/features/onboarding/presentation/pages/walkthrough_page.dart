import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/responsive/responsive_helper.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/providers.dart';

class WalkthroughPage extends ConsumerStatefulWidget {
  const WalkthroughPage({super.key});

  @override
  ConsumerState<WalkthroughPage> createState() => _WalkthroughPageState();
}

class _WalkthroughPageState extends ConsumerState<WalkthroughPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WalkthroughStep> _steps = [
    WalkthroughStep(
      icon: Icons.family_restroom,
      title: 'Welcome to MyFamily',
      description:
          'Keep your family organized and connected with tasks, groceries, calendar, and more—all in one place.',
      color: Colors.blue,
    ),
    WalkthroughStep(
      icon: Icons.task_alt,
      title: 'Manage Tasks & Chores',
      description:
          'Create tasks, assign them to family members, and track completion. Earn points for completing chores!',
      color: Colors.green,
    ),
    WalkthroughStep(
      icon: Icons.shopping_cart,
      title: 'Smart Grocery Lists',
      description:
          'Create reusable templates, assign shopping trips, and never forget an item again.',
      color: Colors.orange,
    ),
    WalkthroughStep(
      icon: Icons.calendar_today,
      title: 'Family Calendar',
      description:
          'Keep track of events, appointments, and important dates for the whole family.',
      color: Colors.purple,
    ),
    WalkthroughStep(
      icon: Icons.emoji_events,
      title: 'Gamification & Points',
      description:
          'Earn points for completing tasks, build streaks, and compete on the family leaderboard!',
      color: Colors.amber,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeWalkthrough() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        // Mark walkthrough as completed in user metadata
        await authRepo.updateUserMetadata({'walkthrough_completed': true});

        // Invalidate user profile to refresh
        ref.invalidate(userProfileProvider(currentUser.id));

        if (mounted) {
          context.go(AppConstants.routeHome);
        }
      } catch (e) {
        // If update fails, still proceed to home
        if (mounted) {
          context.go(AppConstants.routeHome);
        }
      }
    } else {
      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeWalkthrough();
    }
  }

  void _skipWalkthrough() {
    _completeWalkthrough();
  }

  @override
  Widget build(BuildContext context) {
    // Current step color for background
    final currentColor = _steps[_currentPage].color;
    final bool isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentColor.withValues(alpha: 0.1),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: ResponsiveHelper.padding(all: 16),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isLastPage ? 0.0 : 1.0,
                    child: TextButton(
                      onPressed: isLastPage ? null : _skipWalkthrough,
                      child: Text(
                        'Skip',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    // Calculate opacity and transform based on scroll if needed,
                    // but simple builder is cleaner for now.
                    // We can animate the transition of the content.
                    bool isActive = index == _currentPage;
                    return AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      opacity: isActive ? 1.0 : 0.0,
                      child: Transform.translate(
                        offset: isActive ? Offset.zero : const Offset(0, 50),
                        child: _buildStep(_steps[index]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Section: Indicators + Navigation
              Padding(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 32),
                child: Column(
                  children: [
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _steps.length,
                        (index) => _buildPageIndicator(
                          index == _currentPage,
                          _steps[index].color,
                        ),
                      ),
                    ),

                    SizedBox(height: ResponsiveHelper.h(32)),

                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _currentPage > 0 ? 1.0 : 0.0,
                          child: TextButton(
                            onPressed: _currentPage > 0
                                ? () {
                                    _pageController.previousPage(
                                      duration: const Duration(
                                        milliseconds: 400,
                                      ),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                : null,
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            child: const Text('Back'),
                          ),
                        ),

                        // Next/Get Started Button
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: isLastPage
                              ? ResponsiveHelper.w(180)
                              : ResponsiveHelper.w(120),
                          height: ResponsiveHelper.h(50),
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentColor,
                              foregroundColor: Colors.white,
                              elevation: isLastPage ? 8 : 2,
                              shadowColor: currentColor.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: ResponsiveHelper.borderRadius(30),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLastPage ? 'Get Started' : 'Next',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (!isLastPage) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(WalkthroughStep step) {
    return Padding(
      padding: ResponsiveHelper.padding(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with subtle pulse glow
          Container(
            width: ResponsiveHelper.w(160),
            height: ResponsiveHelper.w(160),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: ResponsiveHelper.iconSize(80),
              color: step.color,
            ),
          ),

          SizedBox(height: ResponsiveHelper.h(50)),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: ResponsiveHelper.h(24)),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.6,
              fontSize: ResponsiveHelper.sp(16),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: ResponsiveHelper.padding(horizontal: 6),
      width: isActive ? ResponsiveHelper.w(32) : ResponsiveHelper.w(10),
      height: ResponsiveHelper.h(10),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: ResponsiveHelper.borderRadius(10),
      ),
    );
  }
}

class WalkthroughStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  WalkthroughStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
