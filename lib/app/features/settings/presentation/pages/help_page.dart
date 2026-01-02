import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/user_extensions.dart';

import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/modern_card.dart';

class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Help & Support',
              leading: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              actions: [
                Padding(
                  padding: ResponsiveHelper.padding(right: 8),
                  child: GestureDetector(
                    onTap: () => context.push(AppConstants.routeProfile),
                    child: AvatarWidget(
                      avatarPath: currentUser?.avatarUrl,
                      radius: ResponsiveHelper.r(16),
                      displayName:
                          currentUser?.userMetadata?['full_name'] as String? ??
                          'User',
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      textColor: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.padding(all: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Getting Started
                    _buildSectionHeader(context, 'Getting Started'),
                    _buildFAQCard(context),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // Common Questions
                    _buildSectionHeader(context, 'Common Questions'),
                    _buildCommonQuestionsCard(context),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // Contact Support
                    _buildSectionHeader(context, 'Support'),
                    _buildSupportCard(context),

                    SizedBox(height: ResponsiveHelper.h(32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: ResponsiveHelper.padding(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildFAQCard(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        leading: Icon(
          Icons.help_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('How do I create a family?'),
        children: [
          Padding(
            padding: ResponsiveHelper.padding(all: 16),
            child: Text(
              'To create a family, go to the Profile tab and tap "Create Family". Enter your family name and address, then you\'ll receive a family code that you can share with other members.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommonQuestionsCard(BuildContext context) {
    final questions = [
      {
        'question': 'How do I add tasks?',
        'answer':
            'Go to the Tasks tab and tap the "+" button. Fill in the task details, assign it to a family member, and set a due date if needed.',
      },
      {
        'question': 'How do I create a shopping list?',
        'answer':
            'Go to the Shopping tab and tap the "+" button. You can create a new list or import items from a template. You can also create a shopping list when creating a grocery task.',
      },
      {
        'question': 'How do points work?',
        'answer':
            'Points are automatically awarded when you complete tasks. The points are tracked per family member and displayed on the leaderboard. Complete more tasks to earn more points!',
      },
      {
        'question': 'Can I edit a completed task?',
        'answer':
            'No, completed tasks cannot be edited. If you need to make changes, unmark the task as complete first, then you can edit it.',
      },
      {
        'question': 'How do I join a family?',
        'answer':
            'Ask a family member for the family code. Then go to Profile > Join Family and enter the code. You\'ll be added to the family once the code is verified.',
      },
    ];

    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: questions.map((qa) {
          final isLast = questions.last == qa;
          return Column(
            children: [
              ExpansionTile(
                title: Text(qa['question'] as String),
                children: [
                  Padding(
                    padding: ResponsiveHelper.padding(all: 16),
                    child: Text(
                      qa['answer'] as String,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.email,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Email Support'),
            subtitle: const Text('support@myfamily.app'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onTap: () async {
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'support@myfamily.app',
                query: 'subject=MyFamily App Support Request',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Unable to open email client'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.bug_report,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Report a Bug'),
            subtitle: const Text('Help us improve the app'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            onTap: () async {
              final emailUri = Uri(
                scheme: 'mailto',
                path: 'support@myfamily.app',
                query: 'subject=Bug Report - MyFamily App',
              );
              if (await canLaunchUrl(emailUri)) {
                await launchUrl(emailUri);
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Unable to open email client'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              }
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.info_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('App Version'),
            subtitle: const Text('Version 1.0.0 (Build 1)'),
          ),
        ],
      ),
    );
  }
}
