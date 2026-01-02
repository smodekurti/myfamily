import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../data/models/grocery_template_model.dart';
import '../../../../data/models/family_model.dart';
import 'grocery_list_page.dart'; // For groceryTemplatesProvider

class GroceryTemplateDetailPage extends ConsumerStatefulWidget {
  final String templateId;

  const GroceryTemplateDetailPage({super.key, required this.templateId});

  @override
  ConsumerState<GroceryTemplateDetailPage> createState() =>
      _GroceryTemplateDetailPageState();
}

class _GroceryTemplateDetailPageState
    extends ConsumerState<GroceryTemplateDetailPage> {
  final TextEditingController _itemController = TextEditingController();
  bool _isListView = false; // false = category view, true = list view

  Set<String> _selectedCategories = {}; // Empty set = show all categories
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Always refresh from server when detail page opens (header-detail relationship)
    // This ensures we have the latest data, especially if items were modified by other users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(groceryTemplateItemsProvider(widget.templateId));
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          ref.invalidate(groceryTemplatesProvider(currentFamily.id));
        }
      }
    });

    // Add listener to scroll to bottom when focus changes
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // Small delay to allow keyboard to appear and view to resize
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final templates = currentFamily != null
        ? ref.watch(groceryTemplatesProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryTemplateModel>[]);

    final templateItems = ref.watch(
      groceryTemplateItemsProvider(widget.templateId),
    );

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: !isKeyboardOpen,
          child: Column(
            children: [
              // Custom App Bar
              _buildCustomAppBar(context, templates, currentFamily),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh from server when user pulls to refresh
                    ref.invalidate(
                      groceryTemplateItemsProvider(widget.templateId),
                    );
                    final currentFamily = ref.read(currentFamilyProvider);
                    if (currentFamily != null) {
                      ref.invalidate(
                        groceryTemplatesProvider(currentFamily.id),
                      );
                    }
                    // Wait a moment for the stream to fetch new data
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: ResponsiveHelper.padding(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category Filters (only in category view)
                        templateItems.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return _buildEmptyState(context);
                            }

                            if (!_isListView) {
                              // Show category filters
                              final allCategories =
                                  items
                                      .map((item) => item.category)
                                      .toSet()
                                      .toList()
                                    ..sort();
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildCategoryFilters(context, allCategories),
                                  SizedBox(height: ResponsiveHelper.h(16)),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        // Template Items - Category View or List View
                        templateItems.when(
                          data: (items) {
                            if (items.isEmpty) {
                              return const SizedBox.shrink();
                            }

                            // Apply category filter
                            final filteredItems = _selectedCategories.isEmpty
                                ? items
                                : items
                                      .where(
                                        (item) => _selectedCategories.contains(
                                          item.category,
                                        ),
                                      )
                                      .toList();

                            if (_isListView) {
                              // List View - all items in one list
                              return _buildListView(context, filteredItems);
                            } else {
                              // Category View - compact, grouped by category
                              final groupedItems = _groupItemsByCategory(
                                filteredItems,
                              );

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Items by category - compact view
                                  ...groupedItems.entries.map((entry) {
                                    return _buildCompactCategorySection(
                                      context,
                                      entry.key,
                                      entry.value,
                                    );
                                  }),
                                ],
                              );
                            }
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              Center(child: Text('Error: $error')),
                        ),

                        SizedBox(
                          height: ResponsiveHelper.h(80),
                        ), // Space for bottom input
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom input and add button
              _buildBottomInput(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(
    BuildContext context,
    AsyncValue<List<GroceryTemplateModel>> templates,
    FamilyModel? currentFamily,
  ) {
    return Container(
      padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                templates.when(
                  data: (list) {
                    final template = list.firstWhere(
                      (t) => t.id == widget.templateId,
                      orElse: () => GroceryTemplateModel(
                        id: widget.templateId,
                        familyId: '',
                        name: 'Template',
                        createdBy: '',
                      ),
                    );
                    return Text(
                      template.name,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    );
                  },
                  loading: () => Text(
                    'Template',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  error: (_, __) => Text(
                    'Template',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (currentFamily != null)
                  Text(
                    currentFamily.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          // View Toggle Button
          IconButton(
            icon: Icon(
              _isListView ? Icons.view_module : Icons.view_list,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
            tooltip: _isListView ? 'Category View' : 'List View',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            iconColor: Theme.of(context).colorScheme.onSurface,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: ResponsiveHelper.borderRadius(12),
            ),
            onSelected: (value) {
              if (value == 'create_list') {
                _createShoppingListFromTemplate(context);
              } else if (value == 'edit_name') {
                _editTemplateName(context);
              } else if (value == 'delete_template') {
                _deleteTemplate(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'create_list',
                child: Row(
                  children: [
                    Icon(
                      Icons.shopping_cart,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: ResponsiveHelper.iconSize(20),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Text(
                      'Create Shopping List',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'edit_name',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: ResponsiveHelper.iconSize(20),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Text(
                      'Edit Name',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_template',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: ResponsiveHelper.iconSize(20),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Text(
                      'Delete Template',
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
    );
  }

  Widget _buildCategoryFilters(BuildContext context, List<String> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // "All" filter chip
          FilterChip(
            label: const Text('All'),
            selected: _selectedCategories.isEmpty,
            onSelected: (selected) {
              setState(() {
                _selectedCategories.clear();
              });
            },
            selectedColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.2),
            checkmarkColor: Theme.of(context).colorScheme.primary,
            labelStyle: TextStyle(
              color: _selectedCategories.isEmpty
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: _selectedCategories.isEmpty
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(8)),
          // Category filter chips
          ...categories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return Padding(
              padding: EdgeInsets.only(right: ResponsiveHelper.w(8)),
              child: FilterChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompactCategorySection(
    BuildContext context,
    String category,
    List<GroceryTemplateItemModel> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact category header with badge
        Container(
          padding: ResponsiveHelper.padding(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: ResponsiveHelper.borderRadius(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Container(
                padding: ResponsiveHelper.padding(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: ResponsiveHelper.borderRadius(12),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: ResponsiveHelper.sp(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        Card(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: ResponsiveHelper.borderRadius(12),
          ),
          child: Column(
            children: items
                .map((item) => _buildTemplateItem(context, item))
                .toList(),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
      ],
    );
  }

  Widget _buildTemplateItem(
    BuildContext context,
    GroceryTemplateItemModel item,
  ) {
    final hasQuantity = item.unit != null && item.defaultQty > 0;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return ListTile(
      contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
      title: Text(item.name),
      subtitle: (hasQuantity || hasNotes)
          ? Padding(
              padding: EdgeInsets.only(top: ResponsiveHelper.h(4)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasQuantity)
                    Text(
                      '${item.defaultQty} ${item.unit}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: ResponsiveHelper.sp(12),
                      ),
                    ),
                  if (hasNotes)
                    Padding(
                      padding: EdgeInsets.only(
                        top: hasQuantity ? ResponsiveHelper.h(4) : 0,
                      ),
                      child: Container(
                        padding: ResponsiveHelper.padding(all: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: ResponsiveHelper.borderRadius(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_outlined,
                              size: ResponsiveHelper.iconSize(16),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: ResponsiveHelper.w(8)),
                            Expanded(
                              child: Text(
                                item.notes!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontSize: ResponsiveHelper.sp(12),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
      trailing: IconButton(
        icon: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.error,
          size: ResponsiveHelper.iconSize(20),
        ),
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('Delete Item'),
              content: Text('Are you sure you want to delete "${item.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
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
              final templateRepo = ref.read(groceryTemplateRepositoryProvider);
              await templateRepo.deleteTemplateItem(item.id);

              // Invalidate provider to refresh the list
              ref.invalidate(groceryTemplateItemsProvider(widget.templateId));

              if (mounted) {
                // Success SnackBar removed as per user request
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete item: ${e.toString()}'),
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildListView(
    BuildContext context,
    List<GroceryTemplateItemModel> items,
  ) {
    // Sort items by category, then by name
    items.sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.name.compareTo(b.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // All items - compact list
        if (items.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: ResponsiveHelper.borderRadius(8),
            ),
            child: Column(
              children: [
                ...items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == items.length - 1;
                  return _buildCompactTemplateItem(context, item, isLast);
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactTemplateItem(
    BuildContext context,
    GroceryTemplateItemModel item,
    bool isLast,
  ) {
    final hasQuantity = item.unit != null && item.defaultQty > 0;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return InkWell(
      onTap: () => _showAddItemDialog(context, item: item),
      child: Container(
        padding: ResponsiveHelper.padding(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
        ),
        child: Row(
          children: [
            // Item name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: ResponsiveHelper.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (hasQuantity)
                        Padding(
                          padding: EdgeInsets.only(left: ResponsiveHelper.w(8)),
                          child: Text(
                            '${item.defaultQty} ${item.unit}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: ResponsiveHelper.sp(11),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (hasNotes)
                    Padding(
                      padding: EdgeInsets.only(top: ResponsiveHelper.h(2)),
                      child: Row(
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: ResponsiveHelper.iconSize(12),
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          SizedBox(width: ResponsiveHelper.w(4)),
                          Expanded(
                            child: Text(
                              item.notes!,
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.8),
                                fontSize: ResponsiveHelper.sp(11),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInput(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Container(
      padding: ResponsiveHelper.padding(
        top: 16,
        horizontal: 16,
        bottom: isKeyboardOpen ? 0 : 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, -ResponsiveHelper.h(2)),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: ResponsiveHelper.borderRadius(12),
              ),
              child: TextField(
                controller: _itemController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Add an item...',
                  hintStyle: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: ResponsiveHelper.padding(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    _addItem(context, value.trim());
                  }
                },
              ),
            ),
          ),
          SizedBox(width: ResponsiveHelper.w(12)),
          FloatingActionButton(
            onPressed: () {
              if (_itemController.text.trim().isNotEmpty) {
                _addItem(context, _itemController.text.trim());
              }
            },
            mini: true,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.padding(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: ResponsiveHelper.iconSize(60),
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Text(
              'No items yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            Text(
              'Add items to this template',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<GroceryTemplateItemModel>> _groupItemsByCategory(
    List<GroceryTemplateItemModel> items,
  ) {
    final grouped = <String, List<GroceryTemplateItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  Future<void> _addItem(BuildContext context, String itemName) async {
    // Show dialog to add item
    _showAddItemDialog(context, initialName: itemName);
  }

  Future<void> _showAddItemDialog(
    BuildContext context, {
    GroceryTemplateItemModel? item,
    String? initialName,
  }) async {
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);
    final templateId = widget.templateId;

    // Show dialog using a standalone widget
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AddTemplateItemDialog(
        item: item,
        initialName: initialName,
        onSave:
            (
              String name,
              String category,
              int qty,
              String? unit,
              String? notes,
            ) async {
              try {
                if (item == null) {
                  // Add new item
                  await templateRepo.createTemplateItem(
                    templateId: templateId,
                    name: name,
                    category: category,
                    defaultQty: qty,
                    unit: unit,
                    notes: notes,
                  );
                  _itemController.clear();
                } else {
                  // Update existing item - delete and recreate
                  await templateRepo.deleteTemplateItem(item.id);
                  await templateRepo.createTemplateItem(
                    templateId: templateId,
                    name: name,
                    category: category,
                    defaultQty: qty,
                    unit: unit,
                    notes: notes,
                  );
                }
                return true;
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Theme.of(
                        dialogContext,
                      ).colorScheme.error,
                    ),
                  );
                }
                return false;
              }
            },
      ),
    );

    // Invalidate provider after dialog closes to force refresh
    if (result == true && mounted && context.mounted) {
      // Small delay to ensure database write completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && context.mounted) {
          ref.invalidate(groceryTemplateItemsProvider(widget.templateId));
          // Success SnackBar removed as per user request
        }
      });
    }
  }

  Future<void> _createShoppingListFromTemplate(BuildContext context) async {
    try {
      final currentUser = ref.read(currentUserProvider);
      final currentFamily = ref.read(currentFamilyProvider);

      if (currentUser == null || currentFamily == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User not authenticated'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }

      // Navigate to create task page with grocery category and template pre-selected
      context.push(
        '${AppConstants.routeCreateTask}?category=grocery&templateId=${widget.templateId}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _editTemplateName(BuildContext context) async {
    // Read providers outside the dialog and capture values
    final currentFamily = ref.read(currentFamilyProvider);
    final familyId =
        currentFamily?.id; // Capture ID to avoid ref usage in callback
    final templates = currentFamily != null
        ? ref.read(groceryTemplatesProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryTemplateModel>[]);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);

    final template = templates.value?.firstWhere(
      (t) => t.id == widget.templateId,
      orElse: () => GroceryTemplateModel(
        id: widget.templateId,
        familyId: '',
        name: 'Template',
        createdBy: '',
      ),
    );

    if (template == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template not found'),
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
        onSave: (String name) async {
          try {
            await templateRepo.updateTemplate(
              templateId: widget.templateId,
              familyId: currentFamily?.id ?? '',
              name: name,
            );
            return true;
          } catch (e) {
            if (dialogContext.mounted) {
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text('Error: ${e.toString()}'),
                  backgroundColor: Theme.of(dialogContext).colorScheme.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );

    // Invalidate provider after dialog closes to force refresh
    if (result == true && mounted && context.mounted) {
      // Small delay to ensure database write completes
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && context.mounted) {
          if (familyId != null) {
            ref.invalidate(groceryTemplatesProvider(familyId));
            ref.invalidate(groceryTemplateItemsProvider(widget.templateId));
          }
          // Success SnackBar removed as per user request
        }
      });
    }
  }

  Future<void> _deleteTemplate(BuildContext context) async {
    // Read providers outside the dialog and capture values
    final currentFamily = ref.read(currentFamilyProvider);
    final familyId =
        currentFamily?.id; // Capture ID to avoid ref usage in callback
    final templates = currentFamily != null
        ? ref.read(groceryTemplatesProvider(currentFamily.id))
        : const AsyncValue.data(<GroceryTemplateModel>[]);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);

    final template = templates.value?.firstWhere(
      (t) => t.id == widget.templateId,
      orElse: () => GroceryTemplateModel(
        id: widget.templateId,
        familyId: '',
        name: 'Template',
        createdBy: '',
      ),
    );

    if (template == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Template not found'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

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
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        await templateRepo.deleteTemplate(widget.templateId);

        if (mounted) {
          // Invalidate provider after operation, using captured familyId
          if (familyId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ref.invalidate(groceryTemplatesProvider(familyId));
              }
            });
          }
          if (mounted && context.mounted) {
            context.pop(); // Go back to templates/groceries page
            // Success SnackBar removed as per user request
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  final success = await widget.onSave(
                    _nameController.text.trim(),
                  );

                  if (mounted) {
                    setState(() => _isLoading = false);
                    if (success) {
                      Navigator.of(context).pop(true);
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

// Standalone dialog widget for adding/editing template items
class _AddTemplateItemDialog extends StatefulWidget {
  final GroceryTemplateItemModel? item;
  final String? initialName;
  final Future<bool> Function(
    String name,
    String category,
    int qty,
    String? unit,
    String? notes,
  )
  onSave;

  const _AddTemplateItemDialog({
    this.item,
    this.initialName,
    required this.onSave,
  });

  @override
  State<_AddTemplateItemDialog> createState() => _AddTemplateItemDialogState();
}

class _AddTemplateItemDialogState extends State<_AddTemplateItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _qtyController;
  late TextEditingController _unitController;
  late String _selectedCategory;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.item?.name ?? widget.initialName ?? '',
    );
    _notesController = TextEditingController(text: widget.item?.notes ?? '');
    _qtyController = TextEditingController(
      text: widget.item?.defaultQty.toString() ?? '1',
    );
    _unitController = TextEditingController(text: widget.item?.unit ?? '');
    _selectedCategory = widget.item?.category ?? 'produce';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
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
        widget.item == null ? 'Add Item' : 'Edit Item',
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
                // Item Name
                Text(
                  'Item Name',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Apples',
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
                      return 'Please enter an item name';
                    }
                    return null;
                  },
                  autofocus: false,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),

                // Category
                Text(
                  'Category',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'produce', child: Text('Produce')),
                    DropdownMenuItem(
                      value: 'dairy',
                      child: Text('Dairy & Eggs'),
                    ),
                    DropdownMenuItem(value: 'meat', child: Text('Meat')),
                    DropdownMenuItem(value: 'bakery', child: Text('Bakery')),
                    DropdownMenuItem(value: 'frozen', child: Text('Frozen')),
                    DropdownMenuItem(value: 'pantry', child: Text('Pantry')),
                    DropdownMenuItem(
                      value: 'beverages',
                      child: Text('Beverages'),
                    ),
                    DropdownMenuItem(
                      value: 'household',
                      child: Text('Household'),
                    ),
                    DropdownMenuItem(value: 'health', child: Text('Health')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                SizedBox(height: ResponsiveHelper.h(16)),

                // Quantity and Unit Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          TextFormField(
                            controller: _qtyController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: '1',
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
                                return 'Required';
                              }
                              if (int.tryParse(value) == null ||
                                  int.parse(value) < 1) {
                                return 'Must be ≥ 1';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Unit (optional)',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          TextFormField(
                            controller: _unitController,
                            decoration: InputDecoration(
                              hintText: 'e.g., lb, oz, pack',
                              border: OutlineInputBorder(
                                borderRadius: ResponsiveHelper.borderRadius(12),
                              ),
                              contentPadding: ResponsiveHelper.padding(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),

                // Notes
                Text(
                  'Notes (optional)',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Organic, 2% milk',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(all: 16),
                  ),
                  maxLines: 2,
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
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;

                  setState(() => _isLoading = true);

                  final success = await widget.onSave(
                    _nameController.text.trim(),
                    _selectedCategory,
                    int.parse(_qtyController.text.trim()),
                    _unitController.text.trim().isEmpty
                        ? null
                        : _unitController.text.trim(),
                    _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );

                  if (mounted) {
                    setState(() => _isLoading = false);
                    if (success) {
                      Navigator.of(context).pop(true);
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
              : Text(widget.item == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}

final groceryTemplateItemsProvider =
    StreamProvider.family<List<GroceryTemplateItemModel>, String>((
      ref,
      templateId,
    ) {
      final templateRepo = ref.watch(groceryTemplateRepositoryProvider);
      return templateRepo.streamTemplateItems(templateId);
    });
