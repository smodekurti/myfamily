import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/logo_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  String _biometricTypeName = 'Face ID';

  @override
  void initState() {
    super.initState();
    // Delay biometric check to allow native plugins to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkBiometricAvailability();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    // Platform check removed to support both iOS and Android
    // if (!Platform.isIOS) return;

    try {
      final biometricService = ref.read(biometricAuthServiceProvider);

      // Check availability with error handling
      final isAvailable = await biometricService.isAvailable().catchError((e) {
        // Plugin may not be ready yet, return false
        return false;
      });

      if (!isAvailable) {
        if (mounted) {
          setState(() {
            _isBiometricAvailable = false;
            _isBiometricEnabled = false;
          });
        }
        return;
      }

      // Check if enabled
      final isEnabled = await biometricService
          .isBiometricLoginEnabled()
          .catchError((e) {
            return false;
          });

      // Get type name
      final typeName = await biometricService.getBiometricTypeName().catchError(
        (e) {
          return 'Face ID';
        },
      );

      if (mounted) {
        setState(() {
          _isBiometricAvailable = isAvailable;
          _isBiometricEnabled = isEnabled;
          _biometricTypeName = typeName;
        });
      }
    } catch (e) {
      // Silently fail - biometric not available
      if (mounted) {
        setState(() {
          _isBiometricAvailable = false;
          _isBiometricEnabled = false;
        });
      }
    }
  }

  Future<void> _signInWithBiometric() async {
    if (!_isBiometricAvailable || !_isBiometricEnabled) return;

    setState(() => _isLoading = true);

    try {
      final biometricService = ref.read(biometricAuthServiceProvider);

      // Authenticate with Face ID/Touch ID
      final authenticated = await biometricService.authenticate(
        reason: 'Please authenticate to sign in',
      );

      if (!authenticated) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      // Get saved credentials
      final credentials = await biometricService.getSavedCredentials();

      if (credentials == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No saved credentials found. Please sign in with email and password.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Sign in with saved credentials
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(
        email: credentials['email']!,
        password: credentials['password']!,
      );

      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric sign in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      bool shouldSaveBiometrics = false;

      // Capture services before async calls to avoid "ref disposed" errors
      final biometricService = ref.read(biometricAuthServiceProvider);
      final authRepo = ref.read(authRepositoryProvider);

      // Check if we should ask for biometric enablement BEFORE sign in
      // This ensures we have a valid context/widget is mounted
      if (_isBiometricAvailable && !_isBiometricEnabled && mounted) {
        final shouldEnable = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Enable $_biometricTypeName?'),
            content: Text(
              'Would you like to use $_biometricTypeName to sign in quickly next time?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Not Now'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Enable'),
              ),
            ],
          ),
        );
        shouldSaveBiometrics = shouldEnable == true;
      }

      // Attempt sign in
      await authRepo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If sign in was successful (didn't throw), save credentials if requested
      // We use the captured service instance, so this works even if widget unmounted
      if (shouldSaveBiometrics) {
        try {
          await biometricService.saveCredentials(
            email: email,
            password: password,
          );
        } catch (e) {
          debugPrint('Failed to save biometric credentials: $e');
        }
      }

      // AppRouter redirects automatically on auth state change
      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithGoogle();

      // OAuth flow will handle navigation via auth state listener
      // Don't navigate immediately as OAuth is asynchronous
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);

    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithApple();

      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple sign in failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: ResponsiveHelper.padding(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // App logo
                          Center(
                            child: LogoWidget(
                              size: ResponsiveHelper.w(90),
                              showText: true,
                              isAnimated: true,
                            ),
                          ),
                          SizedBox(height: ResponsiveHelper.h(20)),

                          // Face ID / Touch ID / Fingerprint button (if enabled)
                          if (_isBiometricAvailable && _isBiometricEnabled) ...[
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveHelper.buttonHeight(56),
                              child: OutlinedButton.icon(
                                onPressed: _isLoading
                                    ? null
                                    : _signInWithBiometric,
                                icon: Icon(
                                  Icons.face,
                                  size: ResponsiveHelper.iconSize(20),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  'Sign in with $_biometricTypeName',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: ResponsiveHelper.borderRadius(
                                      12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveHelper.h(16)),
                            // Divider
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: ResponsiveHelper.padding(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    'Or',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            SizedBox(height: ResponsiveHelper.h(16)),
                          ],

                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveHelper.h(12)),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length <
                                  AppConstants.minPasswordLength) {
                                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: ResponsiveHelper.h(20)),

                          // Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveHelper.buttonHeight(56),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signInWithEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: ResponsiveHelper.borderRadius(
                                    12,
                                  ),
                                ),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimary,
                                    )
                                  : Text(
                                      'Sign In',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                            ),
                          ),

                          SizedBox(height: ResponsiveHelper.h(16)),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: ResponsiveHelper.padding(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  'Or',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.6),
                                      ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),

                          SizedBox(height: ResponsiveHelper.h(16)),

                          // Google Sign In button
                          SizedBox(
                            width: double.infinity,
                            height: ResponsiveHelper.buttonHeight(56),
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _signInWithGoogle,
                              icon: Image.asset(
                                'assets/icons/google_logo.png',
                                width: ResponsiveHelper.iconSize(20),
                                height: ResponsiveHelper.iconSize(20),
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.login,
                                    size: ResponsiveHelper.iconSize(20),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  );
                                },
                              ),
                              label: Text(
                                'Sign in with Google',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: ResponsiveHelper.borderRadius(
                                    12,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: ResponsiveHelper.h(12)),

                          // Apple Sign In button (iOS only)
                          if (Platform.isIOS)
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveHelper.buttonHeight(56),
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _signInWithApple,
                                icon: Icon(
                                  Icons.apple,
                                  size: ResponsiveHelper.iconSize(20),
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                                label: Text(
                                  'Sign in with Apple',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: ResponsiveHelper.borderRadius(
                                      12,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          SizedBox(height: ResponsiveHelper.h(16)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Sign Up link (fixed at bottom)
              Padding(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go(AppConstants.routeSignUp),
                      child: Text(
                        'Sign Up',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
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
}
