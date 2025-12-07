import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../data/models/grocery_template_model.dart';
import 'grocery_list_page.dart'; // For groceryTemplatesProvider
import 'grocery_template_detail_page.dart'; // For groceryTemplateItemsProvider

class GroceryTemplatesManagePage extends ConsumerStatefulWidget {
  const GroceryTemplatesManagePage({super.key});

  @override
  ConsumerState<GroceryTemplatesManagePage> createState() =>
      _GroceryTemplatesManagePageState();
}

class _GroceryTemplatesManagePageState
    extends ConsumerState<GroceryTemplatesManagePage> {
  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final currentUser = ref.watch(currentUserProvider);

    if (currentFamily == null) {
      return BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              ModernHeader(
                title: 'Shopping Templates',
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
                            currentUser?.userMetadata?['full_name']
                                as String? ??
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
              const Expanded(child: Center(child: Text('No family selected'))),
            ],
          ),
        ),
      );
    }

    final templatesAsync = ref.watch(
      groceryTemplatesProvider(currentFamily.id),
    );

    return BackgroundWidget(
      child: SafeArea(
        child: Column(
          children: [
            ModernHeader(
              title: 'Shopping Templates',
              leading: IconButton(
                icon: Icon(
                  Icons.menu_rounded,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () {
                    context.push('/grocery-template/create');
                  },
                  tooltip: 'Create Template',
                ),
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
              child: templatesAsync.when(
                data: (templates) {
                  if (templates.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildTemplatesList(context, templates);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: ResponsiveHelper.padding(all: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: ResponsiveHelper.iconSize(64),
                          color: Theme.of(context).colorScheme.error,
                        ),
                        SizedBox(height: ResponsiveHelper.h(16)),
                        Text(
                          'Error loading templates',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                        SizedBox(height: ResponsiveHelper.h(8)),
                        Text(
                          error.toString(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.padding(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: ResponsiveHelper.iconSize(80),
              color: Theme.of(context).colorScheme.primary,
            ),
            SizedBox(height: ResponsiveHelper.h(24)),
            Text(
              'No Templates Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Text(
              'Create your first shopping template to quickly add items to your lists',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: ResponsiveHelper.h(32)),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/grocery-template/create');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Template'),
              style: ElevatedButton.styleFrom(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatesList(
    BuildContext context,
    List<GroceryTemplateModel> templates,
  ) {
    return ListView.builder(
      padding: ResponsiveHelper.padding(all: 16),
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        return _buildTemplateCard(context, template);
      },
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    GroceryTemplateModel template,
  ) {
    // Map template name to icon and color
    IconData icon;
    Color iconColor;

    if (template.name.toLowerCase().contains('weekly') ||
        template.name.toLowerCase().contains('grocery')) {
      icon = Icons.shopping_bag;
      iconColor = Theme.of(context).colorScheme.primary;
    } else if (template.name.toLowerCase().contains('pantry')) {
      icon = Icons.kitchen;
      iconColor = Colors.orange;
    } else {
      icon = Icons.shopping_cart;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: ResponsiveHelper.padding(bottom: 12),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(12),
      ),
      child: InkWell(
        onTap: () {
          context.push('/grocery-template/${template.id}');
        },
        borderRadius: ResponsiveHelper.borderRadius(12),
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: Row(
            children: [
              Container(
                width: ResponsiveHelper.w(56),
                height: ResponsiveHelper.h(56),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: ResponsiveHelper.borderRadius(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ResponsiveHelper.iconSize(28),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(16)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.h(4)),
                    Consumer(
                      builder: (context, ref, child) {
                        final templateItemsAsync = ref.watch(
                          groceryTemplateItemsProvider(template.id),
                        );
                        return templateItemsAsync.when(
                          data: (items) => Text(
                            '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                          loading: () => Text(
                            'Loading...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                          error: (_, __) => Text(
                            'Error loading items',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: ResponsiveHelper.iconSize(20),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: ResponsiveHelper.borderRadius(12),
                ),
                onSelected: (value) {
                  if (value == 'view') {
                    context.push('/grocery-template/${template.id}');
                  } else if (value == 'edit') {
                    _editTemplateName(context, template);
                  } else if (value == 'delete') {
                    _deleteTemplate(context, template);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: ResponsiveHelper.iconSize(20),
                        ),
                        SizedBox(width: ResponsiveHelper.w(12)),
                        const Text('View Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: ResponsiveHelper.iconSize(20),
                        ),
                        SizedBox(width: ResponsiveHelper.w(12)),
                        const Text('Edit Name'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: ResponsiveHelper.iconSize(20),
                        ),
                        SizedBox(width: ResponsiveHelper.w(12)),
                        Text(
                          'Delete',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editTemplateName(
    BuildContext context,
    GroceryTemplateModel template,
  ) async {
    // Read providers outside the dialog
    final currentFamily = ref.read(currentFamilyProvider);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);
    final familyId = currentFamily?.id;

    if (currentFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Family not found'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Show dialog using a standalone widget
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditTemplateNameDialog(
        initialName: template.name,
        onSave: (String newName) async {
          try {
            await templateRepo.updateTemplate(
              templateId: template.id,
              familyId: currentFamily.id,
              name: newName,
            );
            return true;
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update name: ${e.toString().replaceAll('Exception: ', '')}',
                  ),
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );

    // Handle result and invalidate provider outside the dialog
    if (result == true && mounted && context.mounted) {
      if (familyId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            ref.invalidate(groceryTemplatesProvider(familyId));
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template name updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    GroceryTemplateModel template,
  ) async {
    // Read providers outside the dialog
    final currentFamily = ref.read(currentFamilyProvider);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);
    final familyId = currentFamily?.id;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete Template'),
        content: Text(
          'Are you sure you want to delete "${template.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await templateRepo.deleteTemplate(template.id);

        if (mounted) {
          // Invalidate provider after operation
          if (familyId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ref.invalidate(groceryTemplatesProvider(familyId));
              }
            });
          }
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Template deleted successfully'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete template: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

// Standalone dialog widget for editing template name
class _EditTemplateNameDialog extends StatefulWidget {
  final String initialName;
  final Future<bool> Function(String) onSave;

  const _EditTemplateNameDialog({
    required this.initialName,
    required this.onSave,
  });

  @override
  State<_EditTemplateNameDialog> createState() =>
      _EditTemplateNameDialogState();
}

class _EditTemplateNameDialogState extends State<_EditTemplateNameDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
      ),
      title: const Text('Edit Template Name'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter template name',
              border: OutlineInputBorder(
                borderRadius: ResponsiveHelper.borderRadius(12),
              ),
              contentPadding: ResponsiveHelper.padding(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a template name';
              }
              return null;
            },
            autofocus: false,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  try {
                    final success = await widget.onSave(
                      _nameController.text.trim(),
                    );
                    if (mounted) {
                      Navigator.of(context).pop(success);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.of(context).pop(false);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
          child: _isLoading
              ? SizedBox(
                  width: ResponsiveHelper.w(20),
                  height: ResponsiveHelper.h(20),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
