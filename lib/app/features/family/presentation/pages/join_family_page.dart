import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class JoinFamilyPage extends ConsumerStatefulWidget {
  const JoinFamilyPage({super.key});

  @override
  ConsumerState<JoinFamilyPage> createState() => _JoinFamilyPageState();
}

class _JoinFamilyPageState extends ConsumerState<JoinFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinFamily() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.joinFamilyByCode(
        inviteCode: _codeController.text.trim(),
        userId: currentUser.id,
      );
      
      // Invalidate the user families provider to force a refresh
      ref.invalidate(userFamiliesProvider(currentUser.id));
      
      // Wait for the stream to update
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join family: ${e.toString()}'),
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
          title: const Text('Join Family'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go(AppConstants.routeFamilySelection),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: ResponsiveHelper.padding(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: ResponsiveHelper.h(40)),
                    
                    // Illustration
                    Container(
                      width: ResponsiveHelper.w(150),
                      height: ResponsiveHelper.h(150),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: ResponsiveHelper.borderRadius(75),
                      ),
                      child: Icon(
                        Icons.group_add,
                        size: ResponsiveHelper.iconSize(60),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(40)),
                    
                    // Title
                    Text(
                      'Join a Family',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.h(16)),
                    
                    Text(
                      'Enter the family code shared by a family member to join their family hub.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: ResponsiveHelper.h(40)),
                    
                    // Family code field
                    TextFormField(
                      controller: _codeController,
                      decoration: const InputDecoration(
                        labelText: 'Enter Family Code',
                        hintText: 'e.g., 223319',
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the family code';
                        }
                        if (value.length < 6) {
                          return 'Family code must be at least 6 characters';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        // Auto-format the code (remove spaces, convert to uppercase)
                        final formatted = value.replaceAll(' ', '').toUpperCase();
                        if (formatted != value) {
                          _codeController.value = _codeController.value.copyWith(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                    ),
                    SizedBox(height: ResponsiveHelper.h(32)),
                    
                    // Join Family button
                    SizedBox(
                      width: double.infinity,
                      height: ResponsiveHelper.buttonHeight(56),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _joinFamily,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : Text(
                                'Join Family',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(height: ResponsiveHelper.h(32)),
                    
                    // Create family link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have a family code? ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () => context.go(AppConstants.routeCreateFamily),
                          child: Text(
                            'Create one',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: ResponsiveHelper.h(40)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
