import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/repositories/consent_repository.dart';

class ConsentPage extends ConsumerStatefulWidget {
  const ConsentPage({super.key});

  @override
  ConsumerState<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends ConsumerState<ConsentPage> {
  bool _hasReadTerms = false;
  bool _hasReadPrivacy = false;
  bool _agreesToTerms = false;
  bool _agreesToPrivacy = false;
  bool _agreesToDataCollection = false;
  bool _isAgeVerified = false;
  bool _isLoading = false;

  final ScrollController _termsScrollController = ScrollController();
  final ScrollController _privacyScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Check if user already has consent for current version
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkExistingConsent();
    });
  }

  @override
  void dispose() {
    _termsScrollController.dispose();
    _privacyScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConsent() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final consentRepo = ref.read(consentRepositoryProvider);
    final needsConsent = await consentRepo.needsConsent(currentUser.id);
    
    if (!needsConsent && mounted) {
      // User already has consent for current version, navigate away
      final routerState = ref.read(routerStateProvider);
      switch (routerState) {
        case RouterState.authenticatedWithoutFamily:
          context.go(AppConstants.routeGetStarted);
          break;
        case RouterState.authenticatedWithFamily:
          context.go(AppConstants.routeFamilySelection);
          break;
        default:
          context.go(AppConstants.routeHome);
      }
    }
  }

  Future<void> _handleConsent() async {
    if (!_agreesToTerms || !_agreesToPrivacy || !_agreesToDataCollection || !_isAgeVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please accept all required consents to continue'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final authRepo = ref.read(authRepositoryProvider);
      final consentRepo = ref.read(consentRepositoryProvider);
      
      // Get current consent version
      final consentContent = await consentRepo.getConsentContent();
      
      // Store consent in user metadata with version
      await authRepo.updateUserMetadata({
        'consent_accepted': true,
        'consent_version': consentContent.version,
        'consent_timestamp': DateTime.now().toIso8601String(),
        'terms_accepted': true,
        'privacy_accepted': true,
        'data_collection_accepted': true,
        'age_verified': true,
      });

      if (mounted) {
        // Navigate based on router state
        final routerState = ref.read(routerStateProvider);
        switch (routerState) {
          case RouterState.authenticatedWithoutFamily:
            context.go(AppConstants.routeGetStarted);
            break;
          case RouterState.authenticatedWithFamily:
            context.go(AppConstants.routeFamilySelection);
            break;
          default:
            context.go(AppConstants.routeHome);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving consent: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDecline() async {
    // Show confirmation dialog
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text(
          'You must accept the terms and policies to use this app. Would you like to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && mounted) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        await authRepo.signOut();
        // Navigation will be handled by router after sign out
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showTermsDialog() async {
    // Fetch content before showing dialog
    final consentRepo = ref.read(consentRepositoryProvider);
    ConsentContent? content;
    
    try {
      content = await consentRepo.getConsentContent();
    } catch (e) {
      // If fetch fails, use default content
      content = consentRepo.getDefaultContent();
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Terms of Service'),
          content: SizedBox(
            width: ResponsiveHelper.w(300),
            height: ResponsiveHelper.h(400),
            child: content != null
                ? Scrollbar(
                    controller: _termsScrollController,
                    child: SingleChildScrollView(
                      controller: _termsScrollController,
                      child: _TermsOfServiceContent(content: content.termsOfService),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _hasReadTerms = true);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('I have read and understood'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPrivacyDialog() async {
    // Fetch content before showing dialog
    final consentRepo = ref.read(consentRepositoryProvider);
    ConsentContent? content;
    
    try {
      content = await consentRepo.getConsentContent();
    } catch (e) {
      // If fetch fails, use default content
      content = consentRepo.getDefaultContent();
    }
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Privacy Policy'),
          content: SizedBox(
            width: ResponsiveHelper.w(300),
            height: ResponsiveHelper.h(400),
            child: content != null
                ? Scrollbar(
                    controller: _privacyScrollController,
                    child: SingleChildScrollView(
                      controller: _privacyScrollController,
                      child: _PrivacyPolicyContent(content: content.privacyPolicy),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _hasReadPrivacy = true);
                Navigator.of(dialogContext).pop();
              },
              child: const Text('I have read and understood'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: ResponsiveHelper.padding(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Legal Consent & Agreements',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                Text(
                  'Please review and accept the following agreements to continue using MyFamily',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(32)),

                // Terms of Service
                _buildConsentCard(
                  context,
                  title: 'Terms of Service',
                  description: 'Our terms and conditions for using the app',
                  hasRead: _hasReadTerms,
                  isAgreed: _agreesToTerms,
                  onRead: _showTermsDialog,
                  onChanged: (value) => setState(() => _agreesToTerms = value),
                ),

                SizedBox(height: ResponsiveHelper.h(16)),

                // Privacy Policy
                _buildConsentCard(
                  context,
                  title: 'Privacy Policy',
                  description: 'How we collect, use, and protect your data',
                  hasRead: _hasReadPrivacy,
                  isAgreed: _agreesToPrivacy,
                  onRead: _showPrivacyDialog,
                  onChanged: (value) => setState(() => _agreesToPrivacy = value),
                ),

                SizedBox(height: ResponsiveHelper.h(16)),

                // Data Collection Consent
                _buildDataCollectionCard(context),

                SizedBox(height: ResponsiveHelper.h(16)),

                // Age Verification
                _buildAgeVerificationCard(context),

                SizedBox(height: ResponsiveHelper.h(32)),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleConsent,
                    style: ElevatedButton.styleFrom(
                      padding: ResponsiveHelper.padding(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: ResponsiveHelper.h(20),
                            width: ResponsiveHelper.w(20),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Accept & Continue',
                            style: TextStyle(
                              fontSize: ResponsiveHelper.sp(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                SizedBox(height: ResponsiveHelper.h(16)),

                // Decline Option
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isLoading ? null : _handleDecline,
                    style: TextButton.styleFrom(
                      padding: ResponsiveHelper.padding(vertical: 16),
                    ),
                    child: Text(
                      'I Do Not Agree - Sign Out',
                      style: TextStyle(
                        fontSize: ResponsiveHelper.sp(16),
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: ResponsiveHelper.h(16)),

                // Legal Disclaimer
                Text(
                  'By continuing, you acknowledge that you have read, understood, and agree to be bound by all the above terms and policies.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool hasRead,
    required bool isAgreed,
    required VoidCallback onRead,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: ResponsiveHelper.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onRead,
                  child: Text(hasRead ? 'Re-read' : 'Read'),
                ),
              ],
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            Row(
              children: [
                Checkbox(
                  value: isAgreed,
                  onChanged: hasRead
                      ? (value) => onChanged(value ?? false)
                      : null,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: hasRead
                        ? () => onChanged(!isAgreed)
                        : null,
                    child: Text(
                      'I have read and agree to the $title',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: hasRead
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCollectionCard(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: ResponsiveHelper.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Collection & Usage',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            Text(
              'We collect and process the following data to provide our services:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            _buildDataPoint(context, 'Account information (name, email)'),
            _buildDataPoint(context, 'Family and member data'),
            _buildDataPoint(context, 'Tasks, events, and calendar data'),
            _buildDataPoint(context, 'Shopping lists and templates'),
            _buildDataPoint(context, 'Profile pictures and avatars'),
            _buildDataPoint(context, 'Device information for app functionality'),
            SizedBox(height: ResponsiveHelper.h(12)),
            Row(
              children: [
                Checkbox(
                  value: _agreesToDataCollection,
                  onChanged: (value) => setState(() => _agreesToDataCollection = value ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreesToDataCollection = !_agreesToDataCollection),
                    child: Text(
                      'I consent to the collection and processing of my data as described above',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPoint(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.h(4)),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: ResponsiveHelper.sp(6),
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: ResponsiveHelper.w(8)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeVerificationCard(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: Padding(
        padding: ResponsiveHelper.padding(all: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Age Verification',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            Text(
              'You must be at least 13 years old (or the age of majority in your jurisdiction) to use this app. By continuing, you confirm that you meet this requirement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            Row(
              children: [
                Checkbox(
                  value: _isAgeVerified,
                  onChanged: (value) => setState(() => _isAgeVerified = value ?? false),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _isAgeVerified = !_isAgeVerified),
                    child: Text(
                      'I confirm that I am at least 13 years old and meet the age requirements',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Terms of Service Content
class _TermsOfServiceContent extends StatelessWidget {
  final String content;
  
  const _TermsOfServiceContent({required this.content});

  @override
  Widget build(BuildContext context) {
    // Split content by lines and format
    final sections = content.split('\n\n').where((s) => s.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final lines = section.split('\n');
        if (lines.isEmpty) return const SizedBox.shrink();
        
        final title = lines.first.trim();
        final content = lines.skip(1).join('\n').trim();
        
        return _buildSection(context, title, content);
      }).toList(),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.h(4)),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// Privacy Policy Content
class _PrivacyPolicyContent extends StatelessWidget {
  final String content;
  
  const _PrivacyPolicyContent({required this.content});

  @override
  Widget build(BuildContext context) {
    // Split content by lines and format
    final sections = content.split('\n\n').where((s) => s.trim().isNotEmpty).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final lines = section.split('\n');
        if (lines.isEmpty) return const SizedBox.shrink();
        
        final title = lines.first.trim();
        final content = lines.skip(1).join('\n').trim();
        
        return _buildSection(context, title, content);
      }).toList(),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveHelper.h(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: ResponsiveHelper.h(4)),
          Text(
            content,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

