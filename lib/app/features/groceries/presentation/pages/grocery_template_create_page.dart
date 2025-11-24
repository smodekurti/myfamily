import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import 'grocery_list_page.dart'; // For groceryTemplatesProvider

class GroceryTemplateCreatePage extends ConsumerStatefulWidget {
  const GroceryTemplateCreatePage({super.key});

  @override
  ConsumerState<GroceryTemplateCreatePage> createState() => _GroceryTemplateCreatePageState();
}

class _GroceryTemplateCreatePageState extends ConsumerState<GroceryTemplateCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    final currentFamily = ref.read(currentFamilyProvider);

    if (currentUser == null || currentFamily == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final templateRepo = ref.read(groceryTemplateRepositoryProvider);
      
      await templateRepo.createTemplate(
        familyId: currentFamily.id,
        name: _nameController.text.trim(),
        createdBy: currentUser.id,
      );

      // Invalidate the templates provider to refresh the list
      ref.invalidate(groceryTemplatesProvider(currentFamily.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Template created successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        // Small delay to ensure the stream picks up the change
        await Future.delayed(const Duration(milliseconds: 300));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
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
          title: const Text('Create Template'),
          backgroundColor: Colors.transparent,
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _createTemplate,
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: ResponsiveHelper.padding(all: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Template Name',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(8)),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Weekly Groceries',
                      border: OutlineInputBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
                      contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a template name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: ResponsiveHelper.h(24)),
                  Text(
                    'After creating the template, you can add items to it and then create shopping lists from it.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

