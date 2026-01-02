import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/background_widget.dart';
import '../../../../common/widgets/permission_aware_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/utils/grocery_category_mapper.dart';
import '../../../../data/models/grocery_template_model.dart';

import '../../../../data/models/task_model.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/repositories/grocery_template_repository.dart';
import '../../../../common/widgets/modern_header.dart';
import '../../../../common/widgets/modern_card.dart';

class GroceryListPage extends ConsumerStatefulWidget {
  final String listId;
  final String?
  from; // 'task' if navigated from task, null if from Shopping tab

  const GroceryListPage({super.key, required this.listId, this.from});

  @override
  ConsumerState<GroceryListPage> createState() => _GroceryListPageState();
}

class _GroceryListPageState extends ConsumerState<GroceryListPage> {
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showCompleted = true;
  String? _selectedTemplateId;
  bool _isListView = false; // false = category view, true = list view
  Set<String> _selectedCategories = {}; // Empty set = show all categories
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();

    // Always refresh from server when detail page opens (header-detail relationship)
    // This ensures we have the latest data, especially if items were modified by other users
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(groceryListProvider(widget.listId));
        ref.invalidate(groceryListItemsProvider(widget.listId));
      }
    });

    // Set up callback to refresh grocery list items when a notification is received
    // This is a fallback when realtime stream isn't working
    // Register immediately, then update after first frame
    _registerGroceryListCallback();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _registerGroceryListCallback();
      }
    });

    // Add listener to scroll to bottom when focus changes
    _focusNode.addListener(_onFocusChange);
  }

  void _registerGroceryListCallback() {
    final listId = widget.listId;
    PushNotificationService().setGroceryListNotificationCallback(() {
      if (mounted) {
        // Refresh the current list's items
        ref.invalidate(groceryListItemsProvider(listId));
        ref.invalidate(groceryListProvider(listId));

        // Also refresh all lists if we have family context
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          ref.invalidate(allGroceryListsProvider(currentFamily.id));
          ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
        }
      }
    });
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
    _searchController.dispose();
    // Don't clear the callback - let the global callback handle it
    // The global callback in main.dart will ensure it's always registered
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final groceryList = ref.watch(groceryListProvider(widget.listId));
    final listItems = ref.watch(groceryListItemsProvider(widget.listId));

    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return BackgroundWidget(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: !isKeyboardOpen,
          child: Column(
            children: [
              // Custom App Bar
              // Custom App Bar
              groceryList.when(
                data: (list) => ModernHeader(
                  title: list?.name ?? 'Shopping List',
                  subtitle: currentFamily?.name,
                  showBackButton: true,
                  onBack: () => context.pop(),
                  actions: [
                    // Search Button
                    IconButton(
                      icon: Icon(
                        _isSearchMode ? Icons.close : Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      onPressed: () {
                        setState(() {
                          _isSearchMode = !_isSearchMode;
                          if (!_isSearchMode) {
                            _searchController.clear();
                          }
                        });
                      },
                      tooltip: _isSearchMode ? 'Close Search' : 'Search',
                    ),
                    // View Toggle Button (hide when searching)
                    if (!_isSearchMode)
                      IconButton(
                        icon: Icon(
                          _isListView ? Icons.view_module : Icons.view_list,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isListView = !_isListView;
                          });
                        },
                        tooltip: _isListView ? 'Category View' : 'List View',
                      ),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
                      onSelected: (value) {
                        if (value == 'create_task') {
                          _createListTask(context, list!);
                        } else if (value == 'save_as_template') {
                          _saveListAsTemplate(context);
                        } else if (value == 'edit_name') {
                          _editListName(context);
                        } else if (value == 'delete_list') {
                          _deleteList(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'create_task',
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Theme.of(context).colorScheme.primary,
                                size: ResponsiveHelper.iconSize(20),
                              ),
                              SizedBox(width: ResponsiveHelper.w(12)),
                              Text(
                                'Create Task',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
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
                                'Edit List Name',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'save_as_template',
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark_add,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: ResponsiveHelper.iconSize(20),
                              ),
                              SizedBox(width: ResponsiveHelper.w(12)),
                              Text(
                                'Save as Template',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete_list',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Theme.of(context).colorScheme.error,
                                size: ResponsiveHelper.iconSize(20),
                              ),
                              SizedBox(width: ResponsiveHelper.w(12)),
                              Text(
                                'Delete List',
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
                loading: () => ModernHeader(
                  title: 'Shopping List',
                  subtitle: currentFamily?.name,
                  showBackButton: true,
                  onBack: () => context.pop(),
                ),
                error: (_, __) => ModernHeader(
                  title: 'Shopping List',
                  subtitle: currentFamily?.name,
                  showBackButton: true,
                  onBack: () => context.pop(),
                ),
              ),

              // Search bar (shown when search mode is active)
              if (_isSearchMode)
                Container(
                  padding: ResponsiveHelper.padding(all: 16),
                  color: Theme.of(context).colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Search items...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: ResponsiveHelper.borderRadius(12),
                            ),
                            contentPadding: ResponsiveHelper.padding(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      SizedBox(width: ResponsiveHelper.w(8)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isSearchMode = false;
                            _searchController.clear();
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ),

              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    // Refresh from server when user pulls to refresh
                    ref.invalidate(groceryListProvider(widget.listId));
                    ref.invalidate(groceryListItemsProvider(widget.listId));
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
                        // Template Section: Show only when viewing from Shopping tab, hide when from task (hide when searching)
                        if (!_isSearchMode)
                          groceryList.when(
                            data: (list) {
                              if (list == null) return const SizedBox.shrink();
                              // Hide template section if navigated from task
                              if (widget.from == 'task')
                                return const SizedBox.shrink();
                              // Show template section when viewing from Shopping tab
                              return _buildTemplateSection(
                                context,
                                currentFamily?.id,
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                        // Category Filters (only in category view, hide when searching)
                        if (!_isSearchMode)
                          listItems.when(
                            data: (items) {
                              // Don't show category filters or empty state here - let main items section handle empty state
                              if (items.isEmpty) {
                                return const SizedBox.shrink();
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
                                    _buildCategoryFilters(
                                      context,
                                      allCategories,
                                    ),
                                    SizedBox(height: ResponsiveHelper.h(16)),
                                  ],
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                        // Section title
                        if (_isSearchMode)
                          Padding(
                            padding: ResponsiveHelper.padding(bottom: 16),
                            child: Text(
                              'Search Results',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),

                        // Grocery Items - Category View or List View
                        listItems.when(
                          data: (items) {
                            if (items.isEmpty && !_isSearchMode) {
                              return _buildEmptyState(context);
                            }

                            var filteredItems = items;

                            // Apply search filter if in search mode
                            if (_isSearchMode &&
                                _searchController.text.isNotEmpty) {
                              filteredItems = _searchGroceryItems(
                                filteredItems,
                                _searchController.text,
                              );
                            } else if (!_isSearchMode) {
                              // Apply category filter (only when not searching)
                              if (_selectedCategories.isNotEmpty) {
                                filteredItems = filteredItems
                                    .where(
                                      (item) => _selectedCategories.contains(
                                        item.category,
                                      ),
                                    )
                                    .toList();
                              }
                            }

                            if (filteredItems.isEmpty) {
                              return Padding(
                                padding: ResponsiveHelper.padding(vertical: 32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: ResponsiveHelper.iconSize(48),
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                      ),
                                      SizedBox(height: ResponsiveHelper.h(16)),
                                      Text(
                                        _isSearchMode
                                            ? 'No items found'
                                            : 'No items',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (_isListView) {
                              // List View - all items in one list
                              return _buildListView(context, filteredItems);
                            } else {
                              // Category View - compact, grouped by category
                              final groupedItems = _groupItemsByCategory(
                                filteredItems,
                              );
                              final uncompletedItems = groupedItems.entries
                                  .where(
                                    (entry) => entry.value.any(
                                      (item) => !item.checked,
                                    ),
                                  )
                                  .toList();
                              final completedItems = groupedItems.entries
                                  .where(
                                    (entry) =>
                                        entry.value.any((item) => item.checked),
                                  )
                                  .toList();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Uncompleted items by category - compact view
                                  ...uncompletedItems.map((entry) {
                                    return _buildCompactCategorySection(
                                      context,
                                      entry.key,
                                      entry.value
                                          .where((item) => !item.checked)
                                          .toList(),
                                    );
                                  }),

                                  // Completed section
                                  if (completedItems.isNotEmpty) ...[
                                    SizedBox(height: ResponsiveHelper.h(16)),
                                    _buildCompletedSection(
                                      context,
                                      completedItems,
                                    ),
                                  ],
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

  Widget _buildTemplateSection(BuildContext context, String? familyId) {
    if (familyId == null) return const SizedBox.shrink();

    final templates = ref.watch(groceryTemplatesProvider(familyId));

    return templates.when(
      data: (templateList) {
        if (templateList.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'IMPORT ITEMS FROM TEMPLATE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            SizedBox(
              height: ResponsiveHelper.h(120),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: templateList.length,
                separatorBuilder: (context, index) =>
                    SizedBox(width: ResponsiveHelper.w(12)),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: ResponsiveHelper.w(140),
                    child: _buildTemplateCard(context, templateList[index]),
                  );
                },
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(24)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildTemplateCard(
    BuildContext context,
    GroceryTemplateModel template,
  ) {
    final isSelected = _selectedTemplateId == template.id;

    // Map template name to icon and color
    IconData icon;
    Color iconColor;

    if (template.name.toLowerCase().contains('weekly') ||
        template.name.toLowerCase().contains('grocery')) {
      // Weekly Groceries - teal milk carton icon
      icon = Icons.shopping_bag;
      iconColor = Theme.of(context).colorScheme.primary; // Teal
    } else if (template.name.toLowerCase().contains('pantry')) {
      // Pantry Restock - orange pantry icon
      icon = Icons.kitchen;
      iconColor = Colors.orange;
    } else {
      icon = Icons.shopping_cart;
      iconColor = Theme.of(context).colorScheme.primary;
    }

    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedTemplateId = template.id;
        });
        await _importFromTemplate(context, template.id);
      },
      child: ModernCard(
        backgroundColor: isSelected
            ? Theme.of(context).cardColor.withValues(alpha: 0.8)
            : Theme.of(context).cardColor,
        border: isSelected
            ? Border.all(color: iconColor, width: ResponsiveHelper.w(2))
            : null,
        padding: ResponsiveHelper.padding(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: ResponsiveHelper.iconSize(32)),
            SizedBox(height: ResponsiveHelper.h(8)),
            Flexible(
              child: Text(
                template.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: ResponsiveHelper.sp(12),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
    List<GroceryListItemModel> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact category header with badge
        Container(
          padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
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
        ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  _buildGroceryItem(context, item),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String category,
    List<GroceryListItemModel> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          category.displayName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary, // Teal
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(12)),
        ModernCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  _buildGroceryItem(context, item),
                  if (!isLast)
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(24)),
      ],
    );
  }

  Widget _buildGroceryItem(BuildContext context, GroceryListItemModel item) {
    // Check if list is linked to a task (viewing from task view)
    final groceryList = ref.watch(groceryListProvider(widget.listId));
    final isTaskLinked = groceryList.maybeWhen(
      data: (list) => list?.taskId != null,
      orElse: () => false,
    );

    final hasQuantity = item.unit != null && item.qty > 0;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return ListTile(
      contentPadding: ResponsiveHelper.padding(horizontal: 12, vertical: 0),
      visualDensity: VisualDensity.compact,
      // Always show checkbox for all grocery list items
      leading: Checkbox(
        value: item.checked,
        onChanged: (value) async {
          final listRepo = ref.read(groceryListRepositoryProvider);
          await listRepo.toggleItem(item.id, value ?? false);
          // Invalidate provider to force refresh
          if (mounted && context.mounted) {
            ref.invalidate(groceryListItemsProvider(widget.listId));
            // Small delay to ensure database write completes, then check task status
            if (isTaskLinked) {
              Future.delayed(const Duration(milliseconds: 200), () {
                if (mounted && context.mounted) {
                  // Check if all items are checked and update task status accordingly
                  _checkAndUpdateTaskStatus();
                }
              });
            }
          }
        },
        activeColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: ResponsiveHelper.borderRadius(4),
        ),
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.checked ? TextDecoration.lineThrough : null,
          color: item.checked
              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
              : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: (hasQuantity || hasNotes)
          ? Padding(
              padding: EdgeInsets.only(top: ResponsiveHelper.h(2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasQuantity)
                    Text(
                      '${item.qty} ${item.unit}',
                      style: TextStyle(
                        color: item.checked
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4)
                            : Theme.of(
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
                                  color: item.checked
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface.withValues(alpha: 0.4)
                                      : Theme.of(context).colorScheme.primary,
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PermissionAwareWidget(
            action: 'edit_list',
            child: IconButton(
              icon: Icon(
                Icons.edit_outlined,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                size: ResponsiveHelper.iconSize(20),
              ),
              onPressed: () => _showAddItemDialog(context, item: item),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Edit item',
            ),
          ),
          // Only show delete button if NOT linked to a task (viewing from shopping list, not task view)
          if (!isTaskLinked)
            PermissionAwareWidget(
              action: 'edit_list',
              child: Padding(
                padding: EdgeInsets.only(left: ResponsiveHelper.w(4)),
                child: IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                    size: ResponsiveHelper.iconSize(20),
                  ),
                  onPressed: () => _deleteItem(context, item),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete item',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedSection(
    BuildContext context,
    List<MapEntry<String, List<GroceryListItemModel>>> completedItems,
  ) {
    final allCompleted = completedItems
        .expand((entry) => entry.value.where((item) => item.checked))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showCompleted = !_showCompleted;
            });
          },
          child: Row(
            children: [
              Text(
                'Completed (${allCompleted.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              Icon(
                _showCompleted ? Icons.expand_less : Icons.expand_more,
                size: ResponsiveHelper.iconSize(20),
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
        if (_showCompleted) ...[
          SizedBox(height: ResponsiveHelper.h(12)),
          ...completedItems.map((entry) {
            return _buildCategorySection(
              context,
              entry.key,
              entry.value.where((item) => item.checked).toList(),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildBottomInput(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final suggestions = currentFamily != null
        ? ref.watch(grocerySuggestionsProvider(currentFamily.id))
        : const AsyncValue.data(<Map<String, dynamic>>[]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Suggestions section
        suggestions.when(
          data: (suggestionsList) {
            if (suggestionsList.isEmpty) return const SizedBox.shrink();

            // Get current list items to filter out already added items
            final currentItems = ref.watch(
              groceryListItemsProvider(widget.listId),
            );
            final existingItemKeys = currentItems.when(
              data: (items) => items
                  .map(
                    (item) =>
                        '${item.name.toLowerCase()}_${item.category.toLowerCase()}',
                  )
                  .toSet(),
              loading: () => <String>{},
              error: (_, __) => <String>{},
            );

            // Filter suggestions to only show items not already in the list
            final filteredSuggestions = suggestionsList
                .where((suggestion) {
                  final key =
                      '${(suggestion['name'] as String).toLowerCase()}_${(suggestion['category'] as String).toLowerCase()}';
                  return !existingItemKeys.contains(key);
                })
                .take(8)
                .toList();

            if (filteredSuggestions.isEmpty) return const SizedBox.shrink();

            return Container(
              height: ResponsiveHelper.h(60),
              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Suggestions',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(4)),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: filteredSuggestions.map((suggestion) {
                        return Padding(
                          padding: EdgeInsets.only(
                            right: ResponsiveHelper.w(8),
                          ),
                          child: ActionChip(
                            label: Text(
                              suggestion['name'] as String,
                              style: TextStyle(
                                fontSize: ResponsiveHelper.sp(12),
                              ),
                            ),
                            onPressed: () {
                              _addItem(
                                context,
                                suggestion['name'] as String,
                                category: suggestion['category'] as String,
                                qty: suggestion['qty'] as int? ?? 1,
                                unit: suggestion['unit'] as String?,
                              );
                            },
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        // Input field
        Container(
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
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: ResponsiveHelper.padding(vertical: 32),
      child: Center(
        child: ModernCard(
          padding: ResponsiveHelper.padding(all: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: ResponsiveHelper.padding(all: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  size: ResponsiveHelper.iconSize(48),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              Text(
                'No items yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: ResponsiveHelper.h(8)),
              Text(
                'Add items or select a template to get started',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GroceryListItemModel> _searchGroceryItems(
    List<GroceryListItemModel> items,
    String query,
  ) {
    if (query.isEmpty) return items;

    final lowerQuery = query.toLowerCase();
    return items.where((item) {
      // Search in name
      if (item.name.toLowerCase().contains(lowerQuery)) return true;

      // Search in category
      if (item.category.toLowerCase().contains(lowerQuery)) return true;

      // Search in notes
      if (item.notes != null && item.notes!.toLowerCase().contains(lowerQuery))
        return true;

      return false;
    }).toList();
  }

  Map<String, List<GroceryListItemModel>> _groupItemsByCategory(
    List<GroceryListItemModel> items,
  ) {
    final grouped = <String, List<GroceryListItemModel>>{};
    for (final item in items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return grouped;
  }

  Widget _buildListView(
    BuildContext context,
    List<GroceryListItemModel> items,
  ) {
    // Separate checked and unchecked items
    final uncheckedItems = items.where((item) => !item.checked).toList();
    final checkedItems = items.where((item) => item.checked).toList();

    // Sort unchecked items by category, then by name
    uncheckedItems.sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.name.compareTo(b.name);
    });

    // Sort checked items by category, then by name
    checkedItems.sort((a, b) {
      final categoryCompare = a.category.compareTo(b.category);
      if (categoryCompare != 0) return categoryCompare;
      return a.name.compareTo(b.name);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Unchecked items - compact list
        if (uncheckedItems.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: ResponsiveHelper.borderRadius(8),
            ),
            child: Column(
              children: [
                ...uncheckedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == uncheckedItems.length - 1;
                  return _buildCompactGroceryItem(context, item, isLast);
                }),
              ],
            ),
          ),
        ],

        // Checked items (collapsible)
        if (checkedItems.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.h(16)),
          _buildCompletedListSection(context, checkedItems),
        ],
      ],
    );
  }

  Widget _buildCompactGroceryItem(
    BuildContext context,
    GroceryListItemModel item,
    bool isLast,
  ) {
    // Check if list is linked to a task (viewing from task view)
    final groceryList = ref.watch(groceryListProvider(widget.listId));
    final isTaskLinked = groceryList.maybeWhen(
      data: (list) => list?.taskId != null,
      orElse: () => false,
    );

    final hasQuantity = item.unit != null && item.qty > 0;
    final hasNotes = item.notes != null && item.notes!.isNotEmpty;

    return InkWell(
      onTap: () => _showAddItemDialog(context, item: item),
      child: Container(
        padding: ResponsiveHelper.padding(horizontal: 8, vertical: 4),
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
            // Always show checkbox for all grocery list items
            SizedBox(
              width: ResponsiveHelper.w(24),
              height: ResponsiveHelper.h(24),
              child: Checkbox(
                value: item.checked,
                onChanged: (value) async {
                  final listRepo = ref.read(groceryListRepositoryProvider);
                  await listRepo.toggleItem(item.id, value ?? false);
                  // Invalidate provider to force refresh
                  if (mounted && context.mounted) {
                    ref.invalidate(groceryListItemsProvider(widget.listId));
                    // Small delay to ensure database write completes, then check task status
                    if (isTaskLinked) {
                      Future.delayed(const Duration(milliseconds: 200), () {
                        if (mounted && context.mounted) {
                          // Check if all items are checked and update task status accordingly
                          _checkAndUpdateTaskStatus();
                        }
                      });
                    }
                  }
                },
                activeColor: Theme.of(context).colorScheme.primary,
                shape: const CircleBorder(),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(8)),
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
                            decoration: item.checked
                                ? TextDecoration.lineThrough
                                : null,
                            color: item.checked
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: ResponsiveHelper.sp(14),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (hasQuantity)
                    Padding(
                      padding: EdgeInsets.only(top: ResponsiveHelper.h(2)),
                      child: Text(
                        '${item.qty} ${item.unit}',
                        style: TextStyle(
                          color: item.checked
                              ? Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4)
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: ResponsiveHelper.sp(12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
                                color: item.checked
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withValues(alpha: 0.4)
                                    : Theme.of(
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
            // Only show delete button if NOT linked to a task (viewing from shopping list, not task view)
            if (!isTaskLinked) ...[
              SizedBox(width: ResponsiveHelper.w(8)),
              // Delete button for compact view
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.7),
                  size: ResponsiveHelper.iconSize(18),
                ),
                onPressed: () => _deleteItem(context, item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Delete item',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedListSection(
    BuildContext context,
    List<GroceryListItemModel> checkedItems,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _showCompleted = !_showCompleted;
            });
          },
          child: Padding(
            padding: ResponsiveHelper.padding(vertical: 4),
            child: Row(
              children: [
                Icon(
                  _showCompleted
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: ResponsiveHelper.iconSize(20),
                ),
                SizedBox(width: ResponsiveHelper.w(8)),
                Text(
                  'Completed (${checkedItems.length})',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.sp(13),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showCompleted) ...[
          SizedBox(height: ResponsiveHelper.h(8)),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: ResponsiveHelper.borderRadius(8),
            ),
            child: Column(
              children: [
                ...checkedItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isLast = index == checkedItems.length - 1;
                  return _buildCompactGroceryItem(context, item, isLast);
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _addItem(
    BuildContext context,
    String itemName, {
    String? category,
    int? qty,
    String? unit,
  }) async {
    // If category is provided, add directly without dialog
    if (category != null) {
      final listRepo = ref.read(groceryListRepositoryProvider);
      try {
        await listRepo.addItem(
          listId: widget.listId,
          name: itemName,
          category: category,
          qty: qty ?? 1,
          unit: unit,
          source: 'suggestion',
        );
        _itemController.clear();
        // Invalidate to refresh the list items so the new item appears
        ref.invalidate(groceryListItemsProvider(widget.listId));
        // Invalidate to refresh suggestions
        final currentFamily = ref.read(currentFamilyProvider);
        if (currentFamily != null) {
          ref.invalidate(grocerySuggestionsProvider(currentFamily.id));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding item: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } else {
      // Show dialog to add item with notes
      _showAddItemDialog(context, initialName: itemName);
    }
  }

  Future<void> _showAddItemDialog(
    BuildContext context, {
    GroceryListItemModel? item,
    String? initialName,
  }) async {
    final listRepo = ref.read(groceryListRepositoryProvider);
    final listId = widget.listId;

    // Show dialog using a standalone widget
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _AddItemDialog(
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
                  await listRepo.addItem(
                    listId: listId,
                    name: name,
                    category: category,
                    qty: qty,
                    unit: unit,
                    notes: notes,
                    source: 'manual',
                  );
                  _itemController.clear();
                } else {
                  // Update existing item
                  await listRepo.updateItem(
                    itemId: item.id,
                    name: name,
                    category: category,
                    qty: qty,
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
          ref.invalidate(groceryListItemsProvider(widget.listId));
        }
      });
    }
  }

  /// Check if all items are checked and update task status accordingly
  Future<void> _checkAndUpdateTaskStatus() async {
    try {
      // Get the grocery list to check if it's linked to a task
      final groceryListAsync = ref.read(groceryListProvider(widget.listId));
      final list = await groceryListAsync.when(
        data: (l) => l,
        loading: () => null,
        error: (_, __) => null,
      );

      if (list == null || list.taskId == null) {
        // Not linked to a task, nothing to do
        return;
      }

      // Fetch items directly from repository to get fresh state (not from provider)
      final listRepo = ref.read(groceryListRepositoryProvider);
      final items = await listRepo.getListItems(widget.listId);

      if (items.isEmpty) {
        // No items, nothing to check
        return;
      }

      // Check if all items are checked
      final allChecked = items.every((item) => item.checked);

      // Get the task to check its current status
      final currentFamily = ref.read(currentFamilyProvider);
      if (currentFamily == null) return;

      final familyTasksAsync = ref.read(familyTasksProvider(currentFamily.id));
      final tasks = await familyTasksAsync.when(
        data: (t) => t,
        loading: () => <TaskModel>[],
        error: (_, __) => <TaskModel>[],
      );

      if (tasks.isEmpty) return;

      final task = tasks.firstWhere(
        (t) => t.id == list.taskId,
        orElse: () => throw Exception('Task not found'),
      );

      final taskActions = ref.read(taskActionsProvider);

      if (allChecked) {
        // All items are checked - mark task as complete if not already
        if (task.status != 'completed') {
          await taskActions.completeTask(task.id);

          // Invalidate task and family member providers immediately to refresh UI
          if (mounted && context.mounted) {
            ref.invalidate(familyTasksProvider(currentFamily.id));
            ref.invalidate(tasksDueTodayProvider(currentFamily.id));
            ref.invalidate(familyMembersProvider(currentFamily.id));
          }

          if (mounted) {
            if (mounted) {
              // Success SnackBar removed as per user request
            }
          }
        }
      } else {
        // Not all items are checked - mark task as pending if it was completed
        if (task.status == 'completed') {
          await taskActions.updateTask(taskId: task.id, status: 'pending');

          // Invalidate task and family member providers immediately to refresh UI
          if (mounted && context.mounted) {
            ref.invalidate(familyTasksProvider(currentFamily.id));
            ref.invalidate(tasksDueTodayProvider(currentFamily.id));
            ref.invalidate(familyMembersProvider(currentFamily.id));
          }

          if (mounted) {
            if (mounted) {
              // Success SnackBar removed as per user request
            }
          }
        }
      }
    } catch (e) {
      // Silently fail - don't interrupt user experience
    }
  }

  Future<void> _deleteItem(
    BuildContext context,
    GroceryListItemModel item,
  ) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Item',
          style: Theme.of(dialogContext).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}"?',
          style: Theme.of(dialogContext).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.onSurface,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final listRepo = ref.read(groceryListRepositoryProvider);
      await listRepo.deleteItem(item.id);

      // Invalidate provider to force refresh
      if (mounted && context.mounted) {
        // Small delay to ensure database write completes
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && context.mounted) {
            ref.invalidate(groceryListItemsProvider(widget.listId));
          }
        });
      }

      if (mounted) {
        if (mounted) {
          // Success SnackBar removed as per user request
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting item: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importFromTemplate(
    BuildContext context,
    String templateId,
  ) async {
    try {
      final templateRepo = ref.read(groceryTemplateRepositoryProvider);
      final listRepo = ref.read(groceryListRepositoryProvider);

      // Get existing list items to check for duplicates
      final existingItems = await listRepo.getListItems(widget.listId);
      final existingItemKeys = existingItems
          .map(
            (item) =>
                '${item.name.toLowerCase()}_${item.category.toLowerCase()}',
          )
          .toSet();

      // Get template items
      final templateItems = await templateRepo.getTemplateItems(templateId);

      if (templateItems.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This template has no items'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Check if ALL items from this template already exist (template already fully imported)
      final templateItemKeys = templateItems
          .map(
            (item) =>
                '${item.name.toLowerCase()}_${item.category.toLowerCase()}',
          )
          .toSet();

      final allItemsExist = templateItemKeys.every(
        (key) => existingItemKeys.contains(key),
      );

      if (allItemsExist) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'This template has already been imported to this list',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Filter out items that already exist in the list (by name and category)
      final itemsToImport = templateItems.where((templateItem) {
        final key =
            '${templateItem.name.toLowerCase()}_${templateItem.category.toLowerCase()}';
        return !existingItemKeys.contains(key);
      }).toList();

      if (itemsToImport.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'All items from this template are already in the list',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      // Add each new item to the list (do NOT copy notes from template)
      for (final templateItem in itemsToImport) {
        await listRepo.addItem(
          listId: widget.listId,
          name: templateItem.name,
          category: templateItem.category,
          qty: templateItem.defaultQty,
          notes: null, // Do not copy notes from template
          unit: templateItem.unit,
          source: 'template',
        );
      }

      // Invalidate provider to force refresh
      if (mounted && context.mounted) {
        // Small delay to ensure all database writes complete
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && context.mounted) {
            ref.invalidate(groceryListItemsProvider(widget.listId));
          }
        });
      }

      if (mounted) {
        // Success message for import removed as per user request
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveListAsTemplate(BuildContext context) async {
    // Read all providers outside the dialog to avoid disposal issues
    final groceryList = ref.read(groceryListProvider(widget.listId));
    final listItems = ref.read(groceryListItemsProvider(widget.listId));
    final currentUser = ref.read(currentUserProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);

    final list = groceryList.value;
    final items = listItems.value;

    if (list == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('List not found'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    if (currentUser == null || currentFamily == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('User not authenticated'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _SaveAsTemplateDialogInline(
        initialName: list.name,
        itemCount: items?.length ?? 0,
        templateRepo: templateRepo,
        familyId: currentFamily.id,
        userId: currentUser.id,
        templateItems: (items ?? [])
            .map(
              (item) => {
                'name': item.name,
                'category': item.category,
                'qty': item.qty,
                'notes': item.notes,
                'unit': item.unit,
              },
            )
            .toList(),
        onSuccess: () {
          if (context.mounted) {
            // Invalidate provider after dialog closes to avoid disposal issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.invalidate(groceryTemplatesProvider(currentFamily.id));
              }
            });
            // Success message for template creation removed as per user request
          }
        },
      ),
    );
  }

  Future<void> _editListName(BuildContext context) async {
    // Read providers outside the dialog and capture ALL values needed
    final groceryList = ref.read(groceryListProvider(widget.listId));
    final listRepo = ref.read(groceryListRepositoryProvider);
    final list = groceryList.value;
    final listId =
        widget.listId; // Capture listId to avoid using widget.listId in dialog

    if (list == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('List not found'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

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

    // Handle result and show success message outside the dialog
    if (result == true && mounted && context.mounted) {
      // Success message for list name update removed as per user request
    }
  }

  Future<void> _deleteList(BuildContext context) async {
    // Read providers outside the dialog and capture ALL values
    final groceryList = ref.read(groceryListProvider(widget.listId));
    final listRepo = ref.read(groceryListRepositoryProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final familyId = currentFamily?.id; // Capture ID
    final list = groceryList.value;
    final listId = widget.listId; // Capture listId
    final listName =
        list?.name ?? 'this list'; // Capture name for confirmation dialog

    if (list == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('List not found'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Delete List'),
        content: Text(
          'Are you sure you want to delete "$listName"? This action cannot be undone.',
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
        await listRepo.deleteList(listId); // Use captured listId

        if (mounted && context.mounted) {
          // Invalidate provider after operation, using captured familyId
          if (familyId != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && context.mounted) {
                ref.invalidate(standaloneGroceryListsProvider(familyId));
              }
            });
          }
          context.pop(); // Go back to groceries page
          if (context.mounted) {
            // Success message for list deletion removed as per user request
          }
        }
      } catch (e) {
        if (mounted && context.mounted) {
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

  Future<void> _createListTask(
    BuildContext context,
    GroceryListModel list,
  ) async {
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

    // Get family members for assignee dropdown
    final memberRepo = ref.read(familyRepositoryProvider);
    final members = await memberRepo.getFamilyMembers(currentFamily.id);

    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (context) => _CreateListTaskDialog(
        listName: list.name,
        members: members,
        currentUserId: currentUser.id,
        onCreate: (title, assigneeId, dueDate) async {
          try {
            // 1. Create the task
            final taskRepo = ref.read(taskRepositoryProvider);
            final task = await taskRepo.createTask(
              title: title,
              familyId: currentFamily.id,
              createdBy: currentUser.id,
              assignedTo: assigneeId,
              dueDate: dueDate,
              category: 'grocery',
              categoryData: {'groceryListId': list.id},
              priority: 'medium',
              status: 'pending',
              points: 10,
            );

            // 2. Link list to task
            final listRepo = ref.read(groceryListRepositoryProvider);
            await listRepo.updateListTaskId(listId: list.id, taskId: task.id);

            // 3. Refresh providers
            if (mounted) {
              ref.invalidate(familyTasksProvider(currentFamily.id));
              ref.invalidate(groceryListProvider(list.id));

              // Success message for task creation removed as per user request
            }
            return true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create task: $e'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }
}

class _CreateListTaskDialog extends StatefulWidget {
  final String listName;
  final List<FamilyMemberModel> members;
  final String currentUserId;
  final Future<bool> Function(
    String title,
    String assigneeId,
    DateTime? dueDate,
  )
  onCreate;

  const _CreateListTaskDialog({
    required this.listName,
    required this.members,
    required this.currentUserId,
    required this.onCreate,
  });

  @override
  State<_CreateListTaskDialog> createState() => _CreateListTaskDialogState();
}

class _CreateListTaskDialogState extends State<_CreateListTaskDialog> {
  late TextEditingController _titleController;
  late String _selectedAssignee;
  DateTime? _selectedDueDate;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: 'Shop for ${widget.listName}',
    );
    _selectedAssignee = widget.currentUserId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: ResponsiveHelper.borderRadius(16),
      ),
      title: const Text('Create Grocery Task'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveHelper.borderRadius(12),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a title' : null,
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              DropdownButtonFormField<String>(
                value: _selectedAssignee,
                decoration: InputDecoration(
                  labelText: 'Assign To',
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveHelper.borderRadius(12),
                  ),
                ),
                items: widget.members.map((member) {
                  return DropdownMenuItem(
                    value: member.uid, // Assuming userId is the key
                    child: Row(
                      children: [
                        // We could add avatars here if available
                        Text(member.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedAssignee = value);
                  }
                },
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDueDate = picked);
                  }
                },
                borderRadius: ResponsiveHelper.borderRadius(12),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    suffixIcon: _selectedDueDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () =>
                                setState(() => _selectedDueDate = null),
                          )
                        : const Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDueDate == null
                        ? 'No due date'
                        : '${_selectedDueDate!.month}/${_selectedDueDate!.day}/${_selectedDueDate!.year}',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isLoading = true);
                  final success = await widget.onCreate(
                    _titleController.text.trim(),
                    _selectedAssignee,
                    _selectedDueDate,
                  );
                  if (mounted && success) {
                    Navigator.pop(context);
                  } else if (mounted) {
                    setState(() => _isLoading = false);
                  }
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create Task'),
        ),
      ],
    );
  }
}

// Standalone dialog widget for saving a list as a template
// Inline dialog widget to properly manage TextEditingController lifecycle
class _SaveAsTemplateDialogInline extends StatefulWidget {
  final String initialName;
  final int itemCount;
  final GroceryTemplateRepository templateRepo;
  final String familyId;
  final String userId;
  final List<Map<String, dynamic>> templateItems;
  final VoidCallback onSuccess;

  const _SaveAsTemplateDialogInline({
    required this.initialName,
    required this.itemCount,
    required this.templateRepo,
    required this.familyId,
    required this.userId,
    required this.templateItems,
    required this.onSuccess,
  });

  @override
  State<_SaveAsTemplateDialogInline> createState() =>
      _SaveAsTemplateDialogInlineState();
}

class _SaveAsTemplateDialogInlineState
    extends State<_SaveAsTemplateDialogInline> {
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
      title: const Text('Save as Template'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Template Name',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: ResponsiveHelper.h(8)),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g., Weekly Groceries',
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
              ),
              SizedBox(height: ResponsiveHelper.h(16)),
              Text(
                'This will create a template with ${widget.itemCount} items.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
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

                  try {
                    await widget.templateRepo.createTemplateFromList(
                      familyId: widget.familyId,
                      name: _nameController.text.trim(),
                      createdBy: widget.userId,
                      items: widget.templateItems,
                    );

                    if (mounted) {
                      Navigator.of(context).pop(true);
                      widget.onSuccess();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to save template: ${e.toString()}',
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _SaveAsTemplateDialog extends StatefulWidget {
  final String initialName;
  final int itemCount;
  final GroceryTemplateRepository templateRepo;
  final String familyId;
  final String userId;
  final List<Map<String, dynamic>> templateItems;
  final VoidCallback onSuccess;

  const _SaveAsTemplateDialog({
    required this.initialName,
    required this.itemCount,
    required this.templateRepo,
    required this.familyId,
    required this.userId,
    required this.templateItems,
    required this.onSuccess,
  });

  @override
  State<_SaveAsTemplateDialog> createState() => _SaveAsTemplateDialogState();
}

class _SaveAsTemplateDialogState extends State<_SaveAsTemplateDialog> {
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
      title: const Text('Save as Template'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template Name',
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
                      return 'Please enter a template name';
                    }
                    return null;
                  },
                  autofocus: false,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Text(
                  'This will create a template with ${widget.itemCount} items.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
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

                  try {
                    await widget.templateRepo.createTemplateFromList(
                      familyId: widget.familyId,
                      name: _nameController.text.trim(),
                      createdBy: widget.userId,
                      items: widget.templateItems,
                    );

                    if (mounted) {
                      Navigator.of(context).pop(true);
                      widget.onSuccess();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            e.toString().replaceAll('Exception: ', ''),
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
              : const Text('Save'),
        ),
      ],
    );
  }
}

// Standalone dialog widget for adding/editing items
class _AddItemDialog extends StatefulWidget {
  final GroceryListItemModel? item;
  final String? initialName;
  final Future<bool> Function(
    String name,
    String category,
    int qty,
    String? unit,
    String? notes,
  )
  onSave;

  const _AddItemDialog({this.item, this.initialName, required this.onSave});

  @override
  State<_AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<_AddItemDialog> {
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
    final initialName = widget.item?.name ?? widget.initialName ?? '';

    if (widget.item != null) {
      _nameController = TextEditingController(text: widget.item!.name);
      _qtyController = TextEditingController(text: widget.item!.qty.toString());
      _unitController = TextEditingController(text: widget.item!.unit ?? '');
      _notesController = TextEditingController(text: widget.item!.notes ?? '');

      // Normalize category (handle mixed case legacy data)
      final category = widget.item!.category.toLowerCase();
      const validCategories = [
        'produce',
        'dairy',
        'meat',
        'bakery',
        'frozen',
        'pantry',
        'beverages',
        'household',
        'health',
        'other',
      ];

      if (validCategories.contains(category)) {
        _selectedCategory = category;
      } else {
        _selectedCategory = 'other';
      }
    } else {
      _nameController = TextEditingController(text: initialName);
      _notesController = TextEditingController(text: '');
      _qtyController = TextEditingController(text: '1');
      _unitController = TextEditingController(text: '');

      if (initialName.isNotEmpty) {
        _selectedCategory = GroceryCategoryMapper.categorizeItem(initialName);
      } else {
        _selectedCategory = 'other';
      }
    }

    // Listen to name changes and auto-categorize (only when adding new items)
    if (widget.item == null) {
      _nameController.addListener(_onNameChanged);
    }
  }

  void _onNameChanged() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      final autoCategory = GroceryCategoryMapper.categorizeItem(name);
      if (mounted && _selectedCategory != autoCategory) {
        setState(() {
          _selectedCategory = autoCategory;
        });
      }
    }
  }

  @override
  void dispose() {
    // Remove listener before disposing controller
    if (widget.item == null) {
      _nameController.removeListener(_onNameChanged);
    }
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
      title: Text(widget.item == null ? 'Add Item' : 'Edit Item'),
      content: SizedBox(
        width: ResponsiveHelper.w(400),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Item Name',
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
                      return 'Please enter item name';
                    }
                    return null;
                  },
                  autofocus: false,
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _qtyController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                          contentPadding: ResponsiveHelper.padding(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) < 1) {
                            return 'Must be > 0';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.w(12)),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _unitController,
                        decoration: InputDecoration(
                          labelText: 'Unit (e.g., lb, oz, pcs)',
                          border: OutlineInputBorder(
                            borderRadius: ResponsiveHelper.borderRadius(12),
                          ),
                          contentPadding: ResponsiveHelper.padding(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  items:
                      const [
                        'produce',
                        'dairy',
                        'meat',
                        'bakery',
                        'frozen',
                        'pantry',
                        'beverages',
                        'household',
                        'health',
                        'other',
                      ].map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                SizedBox(height: ResponsiveHelper.h(16)),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: 'Notes (for task assignee)',
                    hintText: 'Leave instructions for the shopper...',
                    border: OutlineInputBorder(
                      borderRadius: ResponsiveHelper.borderRadius(12),
                    ),
                    contentPadding: ResponsiveHelper.padding(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                ),
              ],
            ),
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

                  try {
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
              : Text(widget.item == null ? 'Add' : 'Save'),
        ),
      ],
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

// Providers
final groceryListProvider = StreamProvider.family<GroceryListModel?, String>((
  ref,
  listId,
) {
  final listRepo = ref.watch(groceryListRepositoryProvider);
  return listRepo.streamListById(listId);
});

final groceryListItemsProvider =
    StreamProvider.family<List<GroceryListItemModel>, String>((ref, listId) {
      final listRepo = ref.watch(groceryListRepositoryProvider);
      return listRepo.streamListItems(listId);
    });

final groceryTemplatesProvider =
    StreamProvider.family<List<GroceryTemplateModel>, String>((ref, familyId) {
      final templateRepo = ref.watch(groceryTemplateRepositoryProvider);
      return templateRepo.streamTemplatesForFamily(familyId);
    });

final standaloneGroceryListsProvider =
    StreamProvider.family<List<GroceryListModel>, String>((ref, familyId) {
      final listRepo = ref.watch(groceryListRepositoryProvider);
      // Get current user for role-based filtering
      final currentUser = ref.watch(currentUserProvider);
      final userId = currentUser?.id;
      return listRepo.streamStandaloneListsForFamily(familyId, userId: userId);
    });

/// Provider for all grocery lists (both standalone and task-linked)
final allGroceryListsProvider =
    StreamProvider.family<List<GroceryListModel>, String>((ref, familyId) {
      final listRepo = ref.watch(groceryListRepositoryProvider);
      // Get current user for role-based filtering
      final currentUser = ref.watch(currentUserProvider);
      final userId = currentUser?.id;
      return listRepo.streamAllListsForFamily(familyId, userId: userId);
    });
