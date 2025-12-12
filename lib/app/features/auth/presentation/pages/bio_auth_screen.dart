import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../common/widgets/background_widget.dart';

import '../../../../core/providers/providers.dart'; // Assuming this holds app state/user providers

class BioAuthScreen extends ConsumerStatefulWidget {
  final VoidCallback onAuthenticated;

  const BioAuthScreen({super.key, required this.onAuthenticated});

  @override
  ConsumerState<BioAuthScreen> createState() => _BioAuthScreenState();
}

class _BioAuthScreenState extends ConsumerState<BioAuthScreen> {
  bool _isAuthenticating = false;
  String _message = 'Unlock with Face ID';

  @override
  void initState() {
    super.initState();
    // Try to authenticate immediately on load
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _message = 'Authenticating...';
    });

    final service = ref.read(biometricAuthServiceProvider);
    final authenticated = await service.authenticate();

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
      });

      if (authenticated) {
        widget.onAuthenticated();
      } else {
        setState(() {
          _message = 'Authentication failed. Tap to retry.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome Back',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _message,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              if (!_isAuthenticating)
                FilledButton.icon(
                  onPressed: _authenticate,
                  icon: const Icon(Icons.face_rounded),
                  label: const Text('Unlock'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Sign out logic if they can't unlock
                  // Ideally check provider for signOut method
                  ref.read(authRepositoryProvider).signOut();
                },
                child: const Text(
                  'Sign Out',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
