import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../common/widgets/background_widget.dart';
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
      description: 'Keep your family organized and connected with tasks, groceries, calendar, and more—all in one place.',
      color: Colors.blue,
    ),
    WalkthroughStep(
      icon: Icons.task_alt,
      title: 'Manage Tasks & Chores',
      description: 'Create tasks, assign them to family members, and track completion. Earn points for completing chores!',
      color: Colors.green,
    ),
    WalkthroughStep(
      icon: Icons.shopping_cart,
      title: 'Smart Grocery Lists',
      description: 'Create reusable templates, assign shopping trips, and never forget an item again.',
      color: Colors.orange,
    ),
    WalkthroughStep(
      icon: Icons.calendar_today,
      title: 'Family Calendar',
      description: 'Keep track of events, appointments, and important dates for the whole family.',
      color: Colors.purple,
    ),
    WalkthroughStep(
      icon: Icons.emoji_events,
      title: 'Gamification & Points',
      description: 'Earn points for completing tasks, build streaks, and compete on the family leaderboard!',
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
        await authRepo.updateUserMetadata({
          'walkthrough_completed': true,
        });
        
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
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
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: ResponsiveHelper.padding(all: 16),
                  child: TextButton(
                    onPressed: _skipWalkthrough,
                    child: Text(
                      'Skip',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildStep(_steps[index]);
                  },
                ),
              ),

              // Page indicator
              Padding(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _steps.length,
                    (index) => _buildPageIndicator(index == _currentPage),
                  ),
                ),
              ),

              // Navigation buttons
              Padding(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button (only show if not on first page)
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          'Back',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // Next/Get Started button
                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: ResponsiveHelper.padding(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _steps.length - 1 ? 'Get Started' : 'Next',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
      padding: ResponsiveHelper.padding(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: ResponsiveHelper.w(120),
            height: ResponsiveHelper.w(120),
            decoration: BoxDecoration(
              color: step.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              size: ResponsiveHelper.iconSize(60),
              color: step.color,
            ),
          ),

          SizedBox(height: ResponsiveHelper.h(40)),

          // Title
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          SizedBox(height: ResponsiveHelper.h(24)),

          // Description
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      margin: ResponsiveHelper.padding(horizontal: 4),
      width: isActive ? ResponsiveHelper.w(24) : ResponsiveHelper.w(8),
      height: ResponsiveHelper.h(8),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
        borderRadius: ResponsiveHelper.borderRadius(4),
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

