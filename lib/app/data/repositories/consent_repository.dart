import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class ConsentContent {
  final String version;
  final String termsOfService;
  final String privacyPolicy;
  final DateTime lastUpdated;

  ConsentContent({
    required this.version,
    required this.termsOfService,
    required this.privacyPolicy,
    required this.lastUpdated,
  });

  factory ConsentContent.fromSupabase(Map<String, dynamic> data) {
    return ConsentContent(
      version: data['version'] as String,
      termsOfService: data['terms_of_service'] as String,
      privacyPolicy: data['privacy_policy'] as String,
      lastUpdated: DateTime.parse(data['last_updated'] as String),
    );
  }
}

class ConsentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  /// Get current consent content from database
  Future<ConsentContent> getConsentContent() async {
    try {
      final response = await _supabase
          .from('consent_content')
          .select()
          .order('last_updated', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        // Fallback to default content if database doesn't have it
        return _getDefaultContent();
      }

      return ConsentContent.fromSupabase(response);
    } catch (e) {
      _logger.e('Get consent content error: $e');
      // Fallback to default content on error
      return _getDefaultContent();
    }
  }

  /// Get user's accepted consent version
  String? getUserConsentVersion(String userId) {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final metadata = user.userMetadata;
      return metadata?['consent_version'] as String?;
    } catch (e) {
      _logger.e('Get user consent version error: $e');
      return null;
    }
  }

  /// Check if user needs to re-consent (either no consent or version mismatch)
  Future<bool> needsConsent(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return true;

      final metadata = user.userMetadata;
      final hasConsented = metadata?['consent_accepted'] == true;
      
      if (!hasConsented) {
        return true; // User hasn't consented at all
      }

      // Check if version matches
      final currentContent = await getConsentContent();
      final userVersion = metadata?['consent_version'] as String?;
      
      if (userVersion == null || userVersion != currentContent.version) {
        return true; // Version mismatch, need to re-consent
      }

      return false; // User has consented to current version
    } catch (e) {
      _logger.e('Check needs consent error: $e');
      return true; // On error, require consent
    }
  }

  /// Public method to get default content (for fallback scenarios)
  ConsentContent getDefaultContent() {
    return _getDefaultContent();
  }

  /// Default content fallback (in case database is not available)
  static ConsentContent _getDefaultContent() {
    return ConsentContent(
      version: '1.0.0',
      termsOfService: _defaultTermsOfService,
      privacyPolicy: _defaultPrivacyPolicy,
      lastUpdated: DateTime.now(),
    );
  }

  static const String _defaultTermsOfService = '''
1. Acceptance of Terms
By accessing and using the MyFamily mobile application ("App"), you accept and agree to be bound by the terms and provision of this agreement.

2. Use License
Permission is granted to temporarily use the App for personal, non-commercial purposes only. This license shall automatically terminate if you violate any of these restrictions.

3. User Account
You are responsible for maintaining the confidentiality of your account credentials. You agree to notify us immediately of any unauthorized use of your account.

4. User Content
You retain ownership of any content you submit through the App. By submitting content, you grant us a license to use, store, and display such content as necessary to provide the service.

5. Prohibited Uses
You may not use the App: (a) for any unlawful purpose; (b) to violate any laws; (c) to transmit harmful code; (d) to collect user data without consent; (e) to impersonate others.

6. Intellectual Property
The App and its original content, features, and functionality are owned by the developer and are protected by international copyright, trademark, and other intellectual property laws.

7. Limitation of Liability
In no event shall the developer be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.

8. Disclaimer
The App is provided "as is" and "as available" without warranties of any kind, either express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, or non-infringement.

9. Termination
We may terminate or suspend your account and access to the App immediately, without prior notice, for any reason, including breach of these Terms.

10. Changes to Terms
We reserve the right to modify these terms at any time. Your continued use of the App after any changes constitutes acceptance of the new terms.

11. Governing Law
These Terms shall be governed by and construed in accordance with applicable laws, without regard to its conflict of law provisions.

12. Contact Information
If you have any questions about these Terms, please contact us through the app support features.
''';

  static const String _defaultPrivacyPolicy = '''
1. Information We Collect
We collect information you provide directly to us, including: account information (name, email), family data, tasks, events, shopping lists, profile pictures, and device information necessary for app functionality.

2. How We Use Your Information
We use the information we collect to: provide and maintain our services, notify you about changes, provide customer support, gather analysis to improve the app, monitor usage, and detect technical issues.

3. Data Storage
Your data is stored securely using Supabase cloud services. We implement appropriate technical and organizational measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

4. Data Sharing
We do not sell, trade, or rent your personal information to third parties. We may share information only with: (a) service providers who assist in operating our app; (b) when required by law; (c) to protect our rights and safety.

5. Third-Party Services
Our app uses third-party services including Supabase (database and authentication), Google Sign-In, and Apple Sign-In. These services have their own privacy policies governing data collection and use.

6. Data Retention
We retain your personal information for as long as your account is active or as needed to provide services. You may request deletion of your data at any time through the app settings.

7. Your Rights
You have the right to: access your personal data, correct inaccurate data, request deletion of your data, object to processing, and withdraw consent at any time.

8. Children's Privacy
Our app is not intended for children under 13. We do not knowingly collect personal information from children under 13. If you are a parent and believe your child has provided us with personal information, please contact us.

9. Security
We implement security measures to protect your information. However, no method of transmission over the Internet or electronic storage is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.

10. International Data Transfers
Your information may be transferred to and maintained on computers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ.

11. Changes to Privacy Policy
We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date.

12. Contact Us
If you have any questions about this Privacy Policy, please contact us through the app support features or email us at the contact information provided in the app.
''';
}

