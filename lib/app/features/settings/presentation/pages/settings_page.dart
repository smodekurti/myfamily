import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../../../core/services/push_notification_service.dart';
// import 'package:package_info_plus/package_info_plus.dart'; // Optional - can be added later
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/user_model.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final Logger _logger = Logger();
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
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
                
                // About
                _buildSectionHeader(context, 'About'),
                _buildAboutCard(context),
                
                SizedBox(height: ResponsiveHelper.h(32)),
              ],
            ),
          ),
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
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
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
            onTap: () => _showThemeSelector(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, UserModel? user) {
    final notificationsEnabled = user?.notificationsEnabled ?? true;

    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: SwitchListTile(
        secondary: Icon(
          Icons.notifications,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: const Text('Push Notifications'),
        subtitle: const Text('Receive notifications for tasks and events'),
        value: notificationsEnabled,
        onChanged: (value) => _updateNotificationPreference(context, value),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
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
    return Card(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
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
              subtitle: Text('Version $_appVersion${_appBuildNumber != null ? ' (Build $_appBuildNumber)' : ''}'),
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

  Future<void> _showThemeSelector(BuildContext context) async {
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
                content: Text('Failed to save theme preference: ${e.toString()}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }
  }

  Future<void> _updateNotificationPreference(BuildContext context, bool enabled) async {
    final authRepo = ref.read(authRepositoryProvider);
    
    try {
      // If enabling notifications, request permission first
      if (enabled) {
        final pushService = PushNotificationService();
        final hasPermission = await pushService.hasPermission();
        
        if (!hasPermission) {
          _logger.i('Requesting notification permission...');
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
                    content: const Text('Notification permission is required to receive notifications'),
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
      await authRepo.updateUserPreferences(
        notificationsEnabled: enabled,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(enabled ? 'Notifications enabled' : 'Notifications disabled'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: AppConstants.snackBarDuration,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notification preference: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

