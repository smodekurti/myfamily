import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';

class CreateFamilyPage extends ConsumerStatefulWidget {
  const CreateFamilyPage({super.key});

  @override
  ConsumerState<CreateFamilyPage> createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends ConsumerState<CreateFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  DateTime? _selectedBirthdate;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  int _calculateAge(DateTime birthdate) {
    final today = DateTime.now();
    int age = today.year - birthdate.year;
    if (today.month < birthdate.month || 
        (today.month == birthdate.month && today.day < birthdate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthdate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birthdate',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );
    
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
      });
    }
  }

  Future<void> _checkAndCreateFamily() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate birthdate
    if (_selectedBirthdate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your birthdate'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final age = _calculateAge(_selectedBirthdate!);
    if (age < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be at least 18 years old to create a family'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Check for duplicate family names
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final userFamiliesAsync = ref.read(userFamiliesProvider(currentUser.id));
      final familyName = _nameController.text.trim();
      
      await userFamiliesAsync.when(
        data: (families) async {
          final duplicateCount = families.where((f) => f.name == familyName).length;
          
          if (duplicateCount > 0) {
            // Show warning dialog
            final shouldContinue = await _showDuplicateNameDialog(familyName, duplicateCount);
            if (shouldContinue == true) {
              await _createFamily();
            }
          } else {
            // No duplicates, proceed directly
            await _createFamily();
          }
        },
        loading: () async {
          // If still loading, just proceed
          await _createFamily();
        },
        error: (_, __) async {
          // If error loading families, just proceed
          await _createFamily();
        },
      );
    }
  }

  Future<bool?> _showDuplicateNameDialog(String familyName, int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: ResponsiveHelper.iconSize(28),
            ),
            SizedBox(width: ResponsiveHelper.w(12)),
            Expanded(
              child: Text(
                'Duplicate Family Name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You already have ${count == 1 ? 'a family' : '$count families'} named "$familyName".',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Container(
              padding: ResponsiveHelper.padding(all: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: ResponsiveHelper.borderRadius(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: ResponsiveHelper.iconSize(16),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: ResponsiveHelper.w(8)),
                      Text(
                        'Tip:',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: ResponsiveHelper.h(8)),
                  Text(
                    'Families will be distinguished by their unique invite code and creation time.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Text(
              'Do you want to create another "$familyName" family?',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _createFamily() async {
    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final familyRepo = ref.read(familyRepositoryProvider);
      await familyRepo.createFamily(
        name: _nameController.text.trim(),
        createdBy: currentUser.id,
        address: _addressController.text.trim().isEmpty 
            ? null 
            : _addressController.text.trim(),
        creatorAge: _calculateAge(_selectedBirthdate!),
        creatorBirthdate: _selectedBirthdate,
      );
      
      // Invalidate the user families provider to force a refresh
      ref.invalidate(userFamiliesProvider(currentUser.id));
      
      // Wait for the stream to update (give it more time)
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        context.go(AppConstants.routeHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create family: ${e.toString()}'),
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

  String _generateFamilyCode() {
    // Generate a 6-digit family code
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Create Family'),
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
                  
                  // Family name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Family Name',
                      hintText: 'e.g., The Wong Family',
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your family name';
                      }
                      if (value.length < 2) {
                        return 'Family name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  
                  // Birthdate field
                  InkWell(
                    onTap: () => _selectBirthdate(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Your Birthdate',
                        hintText: 'Select your birthdate',
                        prefixIcon: const Icon(Icons.cake),
                        suffixIcon: Icon(
                          Icons.calendar_today,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                      ),
                      child: Text(
                        _selectedBirthdate == null
                            ? 'Tap to select your birthdate'
                            : '${_selectedBirthdate!.day}/${_selectedBirthdate!.month}/${_selectedBirthdate!.year}${_selectedBirthdate != null ? ' (Age: ${_calculateAge(_selectedBirthdate!)})' : ''}',
                        style: TextStyle(
                          color: _selectedBirthdate == null
                              ? Theme.of(context).hintColor
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  
                  // Family address field
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Family Address (Optional)',
                      hintText: 'e.g., 123 Main Street, Anytown, USA',
                      prefixIcon: const Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  SizedBox(height: ResponsiveHelper.h(16)),
                  
                  // Family code preview
                  Container(
                    padding: ResponsiveHelper.padding(all: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: ResponsiveHelper.borderRadius(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Code',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(8)),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _generateFamilyCode(),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () async {
                                final code = _generateFamilyCode();
                                await Clipboard.setData(ClipboardData(text: code));
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Family code copied to clipboard'),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Share this code with family members to invite them',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.h(24)),
                  
                  // Create Family button
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.buttonHeight(56),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _checkAndCreateFamily,
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
                              'Create Family',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(height: ResponsiveHelper.h(24)),
                  
                  // Join family link
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "Already have a family code? ",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppConstants.routeJoinFamily),
                        child: Text(
                          'Join Family',
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
