import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/permission_aware_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../data/models/grocery_template_model.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/repositories/grocery_list_repository.dart';
import '../../../../data/repositories/grocery_template_repository.dart';
import 'grocery_list_page.dart'; // For providers
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/modern_card.dart';

class GroceriesPage extends ConsumerStatefulWidget {
  const GroceriesPage({super.key});

  @override
  ConsumerState<GroceriesPage> createState() => _GroceriesPageState();
}

class _GroceriesPageState extends ConsumerState<GroceriesPage> {
  @override
  void initState() {
    super.initState();

    // Set up callback to refresh grocery lists when a notification is received
    // This is a fallback when realtime stream isn't working
    // Register immediately, then update after first frame if family is available
    _registerGroceryListCallback();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _registerGroceryListCallback();
      }
    });
  }

  void _registerGroceryListCallback() {
    final currentFamily = ref.read(currentFamilyProvider);
    if (currentFamily != null) {
      PushNotificationService().setGroceryListNotificationCallback(() {
        if (mounted) {
          // Re-read family ID in case it changed
          final currentFamily = ref.read(currentFamilyProvider);
          if (currentFamily != null) {
            ref.invalidate(allGroceryListsProvider(currentFamily.id));
            ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
          }
        }
      });
    }
  }

  @override
  void dispose() {
    // Don't clear the callback - let the global callback handle it
    // The global callback in main.dart will ensure it's always registered
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final groceryListsAsync = currentFamily != null
        ? ref.watch(allGroceryListsProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryListModel>[]);

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              ModernHeader(
                title: 'Grocery Lists',
                subtitle: 'Manage your shopping lists',
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.inventory_2_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () {
                      context.push(AppConstants.routeGroceryTemplatesManage);
                    },
                    tooltip: 'Manage Templates',
                  ),
                ],
              ),
              Expanded(
                child: groceryListsAsync.when(
                  data: (lists) {
                    if (lists.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildListsList(context, lists);
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text('Error loading lists: $error')),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: PermissionAwareWidget(
          action: 'create_list',
          child: FloatingActionButton.extended(
            onPressed: () => _showCreateListDialog(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'New List',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: ResponsiveHelper.padding(horizontal: 24),
        child: ModernCard(
          padding: ResponsiveHelper.padding(all: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: ResponsiveHelper.padding(all: 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: ResponsiveHelper.iconSize(64),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(24)),
              Text(
                'No Grocery Lists',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(12)),
              Text(
                'Create a new list or import from a template to get started',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveHelper.h(32)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateListDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create New List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: ResponsiveHelper.padding(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListsList(BuildContext context, List<GroceryListModel> lists) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh from server when user pulls to refresh
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          ref.invalidate(allGroceryListsProvider(currentFamily.id));
          ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
        }
        // Wait a moment for the stream to fetch new data
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: ListView.builder(
        padding: ResponsiveHelper.padding(all: 16),
        itemCount: lists.length,
        itemBuilder: (context, index) {
          final list = lists[index];
          return _buildListCard(context, list);
        },
      ),
    );
  }

  Widget _buildListCard(BuildContext context, GroceryListModel list) {
    return ModernCard(
      onTap: () {
        context.push('/grocery-list/${list.id}');
      },
      margin: ResponsiveHelper.padding(bottom: 12),
      child: Padding(
        padding: ResponsiveHelper.padding(all: 16),
        child: Row(
          children: [
            Container(
              width: ResponsiveHelper.w(56),
              height: ResponsiveHelper.h(56),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: ResponsiveHelper.borderRadius(16),
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: ResponsiveHelper.iconSize(28),
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Text(
                    list.updatedAt != null
                        ? 'Updated ${_formatDate(list.updatedAt!)}'
                        : 'No items yet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<List<bool>>(
                  future: Future.wait([
                    checkPermission(ref, 'edit_list'),
                    checkPermission(ref, 'delete_list'),
                  ]),
                  builder: (context, snapshot) {
                    final canEdit = snapshot.data?[0] ?? false;
                    final canDelete = snapshot.data?[1] ?? false;

                    if (!canEdit && !canDelete) {
                      return const SizedBox.shrink();
                    }

                    return PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        size: ResponsiveHelper.iconSize(20),
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          if (canEdit) {
                            _editListName(context, list);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'You do not have permission to edit lists',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        } else if (value == 'delete') {
                          if (canDelete) {
                            _deleteList(context, list);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    'You do not have permission to delete lists',
                                  ),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (canEdit)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  size: ResponsiveHelper.iconSize(20),
                                ),
                                SizedBox(width: ResponsiveHelper.w(12)),
                                Text(
                                  'Edit Name',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (canDelete)
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
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
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showCreateListDialog(BuildContext context) {
    // Read all providers outside the dialog
    final currentUser = ref.read(currentUserProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final listRepo = ref.read(groceryListRepositoryProvider);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);
    final familyId = currentFamily?.id;

    if (currentUser == null || currentFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final templatesAsync = ref.read(groceryTemplatesProvider(currentFamily.id));

    // Show dialog using a standalone widget
    showDialog(
      context: context,
      builder: (dialogContext) => _CreateListDialog(
        userId: currentUser.id,
        currentFamily: currentFamily,
        listRepo: listRepo,
        templateRepo: templateRepo,
        templatesAsync: templatesAsync,
        onSuccess: (String listId) {
          // Invalidate provider after dialog closes
          if (familyId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ref.invalidate(allGroceryListsProvider(familyId));
                ref.invalidate(standaloneGroceryListsProvider(familyId));
                // Navigate after invalidation
                if (context.mounted) {
                  context.push('/grocery-list/$listId');
                }
              }
            });
          }
        },
      ),
    );
  }

  Future<void> _editListName(
    BuildContext context,
    GroceryListModel list,
  ) async {
    // Read providers outside the dialog and capture values
    final listRepo = ref.read(groceryListRepositoryProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final familyId = currentFamily?.id; // Capture ID for invalidation
    final listId = list.id; // Capture listId

    // Show dialog using a standalone widget that doesn't use ref
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EditListNameDialog(
        initialName: list.name,
        onSave: (String newName) async {
          try {
            await listRepo.updateListName(listId: listId, name: newName);
            return true;
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('Failed to update name: ${e.toString()}'),
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
            ref.invalidate(standaloneGroceryListsProvider(familyId));
          }
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('List name updated successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

  Future<void> _deleteList(BuildContext context, GroceryListModel list) async {
    // Read providers outside the dialog and capture values
    final listRepo = ref.read(groceryListRepositoryProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final familyId =
        currentFamily?.id; // Capture ID to avoid ref usage in callback

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "${list.name}"? This action cannot be undone.',
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
        await listRepo.deleteList(list.id);

        if (mounted) {
          // Invalidate provider after operation, using captured familyId
          if (familyId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ref.invalidate(allGroceryListsProvider(familyId));
                ref.invalidate(standaloneGroceryListsProvider(familyId));
              }
            });
          }
          if (mounted && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('List deleted successfully'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete list: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

// Standalone dialog widget for creating a new list
class _CreateListDialog extends StatefulWidget {
  final String userId;
  final FamilyModel currentFamily;
  final GroceryListRepository listRepo;
  final GroceryTemplateRepository templateRepo;
  final AsyncValue<List<GroceryTemplateModel>> templatesAsync;
  final Function(String listId) onSuccess;

  const _CreateListDialog({
    required this.userId,
    required this.currentFamily,
    required this.listRepo,
    required this.templateRepo,
    required this.templatesAsync,
    required this.onSuccess,
  });

  @override
  State<_CreateListDialog> createState() => _CreateListDialogState();
}

class _CreateListDialogState extends State<_CreateListDialog> {
  late TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
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
      title: Text(
        'Create New List',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // List Name
                Text(
                  'List Name',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Weekly Shopping',
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
                      return 'Please enter a list name';
                    }
                    return null;
                  },
                  autofocus: false,
                ),
                // Import from Template Section (only show if templates exist)
                ...widget.templatesAsync.when(
                  data: (templates) {
                    if (templates.isEmpty) {
                      return <Widget>[];
                    }
                    return [
                      SizedBox(height: ResponsiveHelper.h(24)),
                      Text(
                        'Import from Template (Optional)',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      _buildTemplateSelector(context),
                    ];
                  },
                  loading: () => <Widget>[],
                  error: (_, __) => <Widget>[],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
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
                    final newList = await widget.listRepo.createStandaloneList(
                      familyId: widget.currentFamily.id,
                      name: _nameController.text.trim(),
                      templateId: _selectedTemplateId,
                      createdBy: widget.userId,
                    );

                    // If template selected, import items (do NOT copy notes, skip duplicates)
                    if (_selectedTemplateId != null &&
                        _selectedTemplateId!.isNotEmpty) {
                      final templateItems = await widget.templateRepo
                          .getTemplateItems(_selectedTemplateId!);

                      // Get existing items to check for duplicates
                      final existingItems = await widget.listRepo.getListItems(
                        newList.id,
                      );
                      final existingItemKeys = existingItems
                          .map(
                            (item) =>
                                '${item.name.toLowerCase()}_${item.category.toLowerCase()}',
                          )
                          .toSet();

                      // Filter out duplicates
                      final itemsToImport = templateItems.where((templateItem) {
                        final key =
                            '${templateItem.name.toLowerCase()}_${templateItem.category.toLowerCase()}';
                        return !existingItemKeys.contains(key);
                      }).toList();

                      // Add each new item to the list
                      for (final templateItem in itemsToImport) {
                        await widget.listRepo.addItem(
                          listId: newList.id,
                          name: templateItem.name,
                          category: templateItem.category,
                          qty: templateItem.defaultQty,
                          notes: null, // Do not copy notes from template
                          unit: templateItem.unit,
                          source: 'template',
                        );
                      }
                    }

                    if (mounted) {
                      Navigator.of(context).pop();
                      widget.onSuccess(newList.id);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to create list: ${e.toString()}',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                        ),
                      );
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
              : const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildTemplateSelector(BuildContext context) {
    return widget.templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) {
          return Container(
            padding: ResponsiveHelper.padding(all: 16),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: ResponsiveHelper.borderRadius(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: ResponsiveHelper.iconSize(20),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
                SizedBox(width: ResponsiveHelper.w(12)),
                Expanded(
                  child: Text(
                    'No templates available. Create a blank list or add a template first.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Container(
          constraints: BoxConstraints(maxHeight: ResponsiveHelper.h(200)),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
            ),
            borderRadius: ResponsiveHelper.borderRadius(12),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              final isSelected = _selectedTemplateId == template.id;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTemplateId = isSelected ? null : template.id;
                  });
                },
                child: Container(
                  padding: ResponsiveHelper.padding(all: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                        width: index < templates.length - 1 ? 1 : 0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: ResponsiveHelper.w(24),
                        height: ResponsiveHelper.h(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.3),
                            width: 2,
                          ),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: ResponsiveHelper.iconSize(16),
                                color: Theme.of(context).colorScheme.onPrimary,
                              )
                            : null,
                      ),
                      SizedBox(width: ResponsiveHelper.w(12)),
                      Expanded(
                        child: Text(
                          template.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Container(
        padding: ResponsiveHelper.padding(all: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withOpacity(0.1),
          borderRadius: ResponsiveHelper.borderRadius(12),
        ),
        child: Text(
          'Error loading templates: $error',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
    );
  }
}

// Standalone dialog widget that doesn't use ref
class _EditListNameDialog extends StatefulWidget {
  final String initialName;
  final Future<bool> Function(String) onSave;

  const _EditListNameDialog({required this.initialName, required this.onSave});

  @override
  State<_EditListNameDialog> createState() => _EditListNameDialogState();
}

class _EditListNameDialogState extends State<_EditListNameDialog> {
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
      title: const Text('Edit List Name'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: 'Enter list name',
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
                return 'Please enter a list name';
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
