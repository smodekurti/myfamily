import 'package:flutter/material.dart';
import '../../../../core/extensions/user_extensions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/push_notification_service.dart';
// import 'package:package_info_plus/package_info_plus.dart'; // Optional - can be added later
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_model.dart';

import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/modern_card.dart';
import '../../../../common/widgets/avatar_widget.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String? _appVersion;
  String? _appBuildNumber;

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    // App version can be loaded using package_info_plus if needed
    // For now, using hardcoded version from pubspec.yaml
    if (mounted) {
      setState(() {
        _appVersion = '1.0.0';
        _appBuildNumber = '1';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Get user profile for preferences
    final userProfileAsync = currentUser != null
        ? ref.watch(userProfileProvider(currentUser.id))
        : const AsyncValue<UserModel?>.data(null);

    final userProfile = userProfileAsync.when(
      data: (profile) => profile,
      loading: () => null,
      error: (_, __) => null,
    );

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Settings',
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
                    // Theme Settings
                    _buildSectionHeader(context, 'Appearance'),
                    _buildThemeCard(context, themeMode),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // Notification Settings
                    _buildSectionHeader(context, 'Notifications'),
                    _buildNotificationCard(context, userProfile),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // Account Settings
                    _buildSectionHeader(context, 'Account'),
                    _buildAccountCard(context),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // Magic AI Settings
                    _buildSectionHeader(context, 'Magic AI'),
                    _buildMagicPlanCard(context),

                    SizedBox(height: ResponsiveHelper.h(24)),

                    // About
                    _buildSectionHeader(context, 'About'),
                    _buildAboutCard(context),

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

  Widget _buildThemeCard(BuildContext context, ThemeMode currentTheme) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.palette,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Theme'),
            subtitle: Text(_getThemeDescription(currentTheme)),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () => _showThemeSelector(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, UserModel? user) {
    final notificationsEnabled = user?.notificationsEnabled ?? true;

    return ModernCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Push Notifications'),
        subtitle: const Text('Receive notifications for tasks and events'),
        value: notificationsEnabled,
        onChanged: (value) => _updateNotificationPreference(value),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Edit Profile'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () {
              context.push(AppConstants.routeEditProfile);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.family_restroom,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Family Settings'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () {
              context.push(AppConstants.routeFamilySettings);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: const Text('Help & Support'),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            onTap: () {
              context.push(AppConstants.routeHelp);
            },
          ),
          if (_appVersion != null) ...[
            const Divider(height: 1),
            ListTile(
              leading: Icon(
                Icons.info_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('App Version'),
              subtitle: Text(
                'Version $_appVersion${_appBuildNumber != null ? ' (Build $_appBuildNumber)' : ''}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getThemeDescription(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  Future<void> _showThemeSelector() async {
    final currentTheme = ref.read(themeModeProvider);

    final selectedTheme = await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Select Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: currentTheme,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: currentTheme,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              value: ThemeMode.system,
              groupValue: currentTheme,
              onChanged: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
      ),
    );

    if (selectedTheme != null && selectedTheme != currentTheme) {
      // Update theme immediately
      ref.read(themeModeProvider.notifier).state = selectedTheme;

      // Save to user preferences
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final authRepo = ref.read(authRepositoryProvider);
        final themePreference = selectedTheme == ThemeMode.light
            ? 'light'
            : selectedTheme == ThemeMode.dark
            ? 'dark'
            : 'system';

        try {
          await authRepo.updateUserPreferences(
            themePreference: themePreference,
          );
        } catch (e) {
          // Show error but don't block theme change
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to save theme preference: ${e.toString()}',
                ),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _updateNotificationPreference(bool enabled) async {
    final authRepo = ref.read(authRepositoryProvider);

    try {
      // If enabling notifications, request permission first
      if (enabled) {
        final pushService = PushNotificationService();
        final hasPermission = await pushService.hasPermission();

        if (!hasPermission) {
          final permissionGranted = await pushService.requestPermission();

          if (!permissionGranted) {
            // Permission was denied - check if it's permanently denied
            final status = await Permission.notification.status;
            if (status.isPermanentlyDenied) {
              // Show dialog to open settings
              if (mounted) {
                final shouldOpenSettings = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Notification Permission Required'),
                    content: const Text(
                      'To receive notifications, please enable them in your device settings.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Open Settings'),
                      ),
                    ],
                  ),
                );

                if (shouldOpenSettings == true) {
                  await pushService.openNotificationSettings();
                }
              }
            } else {
              // Permission was denied but not permanently - show message
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Notification permission is required to receive notifications',
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    duration: AppConstants.snackBarDuration,
                  ),
                );
              }
            }
            // Don't save preference if permission wasn't granted
            return;
          }
        }
      }

      // Save preference
      await authRepo.updateUserPreferences(notificationsEnabled: enabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled ? 'Notifications enabled' : 'Notifications disabled',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: AppConstants.snackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update notification preference: ${e.toString()}',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildMagicPlanCard(BuildContext context) {
    return ModernCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Magic AI Settings'),
        subtitle: const Text('Manage your Gemini API Key'),
        trailing: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        ),
        onTap: _showKeyManagementDialog,
      ),
    );
  }

  Future<void> _showKeyManagementDialog() async {
    final hasKey = await ref.read(geminiServiceProvider).hasApiKey();
    if (!hasKey) {
      _showApiKeyDialog();
      return;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Gemini API Settings'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              _showApiKeyDialog();
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 12),
                  Text('Update API Key'),
                ],
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () async {
              Navigator.pop(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete API Key?'),
                  content: const Text(
                    'This will remove the key from your device. You will need to enter it again to use Magic features.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(geminiServiceProvider).deleteApiKey();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('API Key deleted')),
                  );
                }
              }
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete API Key', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use Magic Plan, you need a free Google Gemini API Key. The key is stored securely on your device.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Don\'t have a key?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://aistudio.google.com/app/apikey',
                );
                if (!await launchUrl(url)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch URL')),
                    );
                  }
                }
              },
              child: const Text(
                'Get a free API Key here ↗',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Paste API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save Key'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(geminiServiceProvider).setApiKey(result);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API Key saved successfully')),
        );
      }
    }
  }
}
