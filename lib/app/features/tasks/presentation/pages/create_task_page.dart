import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../core/models/task_category.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/grocery_template_model.dart';
import '../../../../data/repositories/grocery_list_repository.dart';
import '../../../../data/repositories/grocery_template_repository.dart';
import '../../../groceries/presentation/pages/grocery_list_page.dart'; // For groceryTemplatesProvider and standaloneGroceryListsProvider
import 'package:intl/intl.dart';

class CreateTaskPage extends ConsumerStatefulWidget {
  final String? initialCategory;
  
  const CreateTaskPage({
    super.key,
    this.initialCategory,
  });

  @override
  ConsumerState<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends ConsumerState<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  String? _selectedAssignee;
  late String _selectedCategory;
  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  String? _selectedGroceryListId;
  String? _templateIdToImport;
  String? _selectedTemplateId; // Task template ID
  String _recurrenceType = 'none'; // 'none', 'daily', 'weekly', 'monthly'
  DateTime? _recurrenceEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'chore';
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check for templateId in query parameters
    final route = GoRouterState.of(context);
    final templateId = route.uri.queryParameters['templateId'];
    if (templateId != null) {
      if (_selectedCategory == 'grocery' && _templateIdToImport == null) {
        _templateIdToImport = templateId;
      } else if (_selectedTemplateId == null) {
        // Load task template
        _loadTaskTemplate(templateId);
      }
    }
  }

  Future<void> _loadTaskTemplate(String templateId) async {
    final templateRepo = ref.read(taskTemplateRepositoryProvider);
    try {
      final template = await templateRepo.getTemplate(templateId);
      if (template != null && mounted) {
        setState(() {
          _selectedTemplateId = templateId;
          _titleController.text = template.title;
          _notesController.text = template.description ?? '';
          _selectedCategory = template.category ?? 'chore';
          _selectedPriority = template.priority ?? 'medium';
          _recurrenceType = template.recurrenceType ?? 'none';
          if (template.recurrenceEndDate != null) {
            _recurrenceEndDate = template.recurrenceEndDate;
          }
        });
      }
    } catch (e) {
      // Silently fail - template might not exist
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  Future<void> _attachShoppingList(BuildContext context) async {
    // Navigate to template selection or create new list
    final result = await context.push('/grocery-list-select');
    if (result != null && result is String) {
      setState(() {
        _selectedGroceryListId = result;
      });
    }
  }

  Future<void> _createNewShoppingList(BuildContext context) async {
    final currentUser = ref.read(currentUserProvider);
    final currentFamily = ref.read(currentFamilyProvider);
    final listRepo = ref.read(groceryListRepositoryProvider);
    final templateRepo = ref.read(groceryTemplateRepositoryProvider);

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

    final templatesAsync = ref.read(groceryTemplatesProvider(currentFamily.id));

    // Show dialog to create new list
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => _CreateShoppingListDialog(
        userId: currentUser.id,
        currentFamily: currentFamily,
        listRepo: listRepo,
        templateRepo: templateRepo,
        templatesAsync: templatesAsync,
      ),
    );

    if (result != null && result.isNotEmpty) {
      // Set the selected list ID so it will be referenced (not copied) when task is saved
      setState(() {
        _selectedGroceryListId = result;
      });
      
      // Navigate to the shopping list page so user can add items
      if (mounted) {
        // Invalidate the standalone lists provider so the new list appears in selection
        ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
        
        // Show a message and navigate to the list page
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Shopping list created! Add items and return to save the task.'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Go to List',
              textColor: Theme.of(context).colorScheme.onPrimary,
              onPressed: () {
                context.push('/grocery-list/$result');
              },
            ),
          ),
        );
        
        // Navigate to the shopping list page
        await context.push('/grocery-list/$result');
        
        // After returning from the list page, refresh the standalone lists
        ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
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
    
    // Auto-assign to current user if no assignee selected
    final assignee = _selectedAssignee ?? currentUser.id;

    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final currentFamily = ref.read(currentFamilyProvider);
      
      if (currentUser == null || currentFamily == null) {
        throw Exception('User not authenticated or no family selected');
      }

      final taskActions = ref.read(taskActionsProvider);
      
      // Get default points for the selected category
      final category = TaskCategories.getById(_selectedCategory);
      final defaultPoints = category?.defaultPoints ?? 10;
      
      // Build categoryData with recurrence info
      Map<String, dynamic>? categoryData;
      if (_recurrenceType != 'none') {
        categoryData = {
          'recurrenceType': _recurrenceType,
        };
        if (_recurrenceEndDate != null) {
          categoryData['recurrenceEndDate'] = _recurrenceEndDate!.toIso8601String();
        }
      }
      
      // Create task (don't set groceryListId in categoryData yet - we'll set it after linking the list)
      final task = await taskActions.createTask(
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        assignedTo: assignee,
        createdBy: currentUser.id,
        familyId: currentFamily.id,
        category: _selectedCategory,
        categoryData: categoryData,
        dueDate: _selectedDueDate,
        priority: _selectedPriority,
        points: defaultPoints,
      );

      // If grocery category, handle grocery list
      // Creating a list from a task works exactly the same as creating from Shopping tab
      // The only difference is we link it to the task after creation
      String? groceryListId;
      if (_selectedCategory == 'grocery') {
        final groceryListRepo = ref.read(groceryListRepositoryProvider);
        
        if (_selectedGroceryListId != null) {
          // User selected an existing list - just link it to this task
          await groceryListRepo.updateListTaskId(
            listId: _selectedGroceryListId!,
            taskId: task.id,
          );
          groceryListId = _selectedGroceryListId!;
        } else if (_templateIdToImport != null) {
          // Create a new list from template (same as Shopping tab)
          final groceryList = await groceryListRepo.createStandaloneList(
            familyId: currentFamily.id,
            name: _titleController.text.trim(),
            createdBy: currentUser.id,
            templateId: _templateIdToImport,
          );
          groceryListId = groceryList.id;
          
          // Import items from template (skip duplicates)
          final templateRepo = ref.read(groceryTemplateRepositoryProvider);
          final templateItems = await templateRepo.getTemplateItems(_templateIdToImport!);
          final existingItems = await groceryListRepo.getListItems(groceryList.id);
          final existingItemKeys = existingItems
              .map((item) => '${item.name.toLowerCase()}_${item.category.toLowerCase()}')
              .toSet();
          
          for (final templateItem in templateItems) {
            final key = '${templateItem.name.toLowerCase()}_${templateItem.category.toLowerCase()}';
            if (!existingItemKeys.contains(key)) {
              await groceryListRepo.addItem(
                listId: groceryList.id,
                name: templateItem.name,
                category: templateItem.category,
                qty: templateItem.defaultQty,
                unit: templateItem.unit,
                source: 'template',
              );
            }
          }
          
          // Link the list to this task
          await groceryListRepo.updateListTaskId(
            listId: groceryListId,
            taskId: task.id,
          );
        } else {
          // Create a new empty list (same as Shopping tab)
          final groceryList = await groceryListRepo.createStandaloneList(
            familyId: currentFamily.id,
            name: _titleController.text.trim(),
            createdBy: currentUser.id,
          );
          groceryListId = groceryList.id;
          
          // Link the list to this task
          await groceryListRepo.updateListTaskId(
            listId: groceryListId,
            taskId: task.id,
          );
        }
        
        // Update task with grocery list ID in categoryData (merge with existing categoryData)
        final updatedCategoryData = Map<String, dynamic>.from(task.categoryData ?? categoryData ?? {});
        updatedCategoryData['groceryListId'] = groceryListId;
        await taskActions.updateTask(
          taskId: task.id,
          categoryData: updatedCategoryData,
        );
      }
      
      // Refresh the tasks list to show the new task immediately
      ref.invalidate(familyTasksProvider(currentFamily.id));
      ref.invalidate(tasksDueTodayProvider(currentFamily.id));
      
      // Invalidate grocery list providers to ensure the list appears in Shopping tab immediately
      if (_selectedCategory == 'grocery' && groceryListId != null) {
        // Small delay to ensure database writes complete before invalidating
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Invalidate the all lists provider so Shopping tab updates immediately
        ref.invalidate(allGroceryListsProvider(currentFamily.id));
        ref.invalidate(standaloneGroceryListsProvider(currentFamily.id));
        
        // Also invalidate specific list providers
        ref.invalidate(groceryListProvider(groceryListId));
        ref.invalidate(groceryListItemsProvider(groceryListId));
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chore created successfully!'),
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
            content: Text('Failed to create chore: ${e.toString()}'),
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

  Future<void> _saveAsTemplate(BuildContext context) async {
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

    final templateRepo = ref.read(taskTemplateRepositoryProvider);
    final nameController = TextEditingController(text: _titleController.text);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: ResponsiveHelper.borderRadius(16),
          ),
          title: const Text('Save as Template'),
          content: SizedBox(
            width: ResponsiveHelper.w(400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g., Weekly Cleaning',
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
                  SizedBox(height: ResponsiveHelper.h(16)),
                  Text(
                    'This will save the current task configuration as a reusable template.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        await templateRepo.createTemplate(
                          familyId: currentFamily.id,
                          name: nameController.text.trim(),
                          title: _titleController.text.trim(),
                          description: _notesController.text.trim().isEmpty
                              ? null
                              : _notesController.text.trim(),
                          category: _selectedCategory,
                          priority: _selectedPriority,
                          points: TaskCategories.getById(_selectedCategory)?.defaultPoints ?? 10,
                          recurrenceType: _recurrenceType != 'none' ? _recurrenceType : null,
                          recurrenceEndDate: _recurrenceEndDate,
                          createdBy: currentUser.id,
                        );

                        if (context.mounted) {
                          Navigator.of(dialogContext).pop(true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Template saved successfully!'),
                              backgroundColor: Theme.of(context).colorScheme.primary,
                            ),
                          );
                          // Invalidate templates provider
                          ref.invalidate(taskTemplatesProvider(currentFamily.id));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save template: ${e.toString()}'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: isLoading
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
        ),
      ),
    );

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    final familyMembers = currentFamily != null 
        ? ref.watch(familyMembersProvider(currentFamily.id))
        : const AsyncValue.data(<FamilyMemberModel>[]);

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.5), // Blurred background
      body: Center(
        child: Container(
          margin: ResponsiveHelper.padding(horizontal: 16),
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.w(400),
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: ResponsiveHelper.borderRadius(20),
          ),
            child: Form(
              key: _formKey,
              child: Column(
              mainAxisSize: MainAxisSize.min,
                children: [
                // Header
                _buildHeader(context),
                
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: ResponsiveHelper.padding(all: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Template selector (if any templates exist)
                        _buildTemplateSelector(context),
                        if (_selectedTemplateId != null) SizedBox(height: ResponsiveHelper.h(16)),
                        
                        // Chore Name
                        _buildChoreNameField(),
                  SizedBox(height: ResponsiveHelper.h(24)),
                  
                        // Category selector
                        _buildCategorySelector(),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Assign To
                        _buildAssignToSection(context, familyMembers),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Priority
                        _buildPrioritySelector(context),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Due Date
                        _buildDueDateField(context),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Recurrence
                        _buildRecurrenceSelector(context),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Shopping List (only if grocery category and no template pre-selected)
                        if (_selectedCategory == 'grocery' && _templateIdToImport == null) ...[
                          _buildShoppingListSection(context),
                          SizedBox(height: ResponsiveHelper.h(24)),
                        ],
                        
                        // Show template info if template is pre-selected
                        if (_selectedCategory == 'grocery' && _templateIdToImport != null) ...[
                          _buildTemplateInfoSection(context),
                          SizedBox(height: ResponsiveHelper.h(24)),
                        ],
                        
                        // Notes
                        _buildNotesField(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: ResponsiveHelper.w(1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          Expanded(
            child: Text(
              'New Chore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Save as Template button
              TextButton.icon(
                onPressed: _isLoading ? null : () => _saveAsTemplate(context),
                icon: Icon(
                  Icons.bookmark_border,
                  size: ResponsiveHelper.iconSize(18),
                ),
                label: Text(
                  'Template',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: ResponsiveHelper.sp(12),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(8)),
              // Save button
              TextButton(
                onPressed: _isLoading ? null : _saveTask,
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
        ],
      ),
    );
  }

  Widget _buildChoreNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chore Name',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
            hintText: 'e.g., Weekly Groceries',
                      border: OutlineInputBorder(
                        borderRadius: ResponsiveHelper.borderRadius(12),
                      ),
            contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
              return 'Please enter a chore name';
                      }
                      return null;
                    },
                  ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    // Get priority categories (most commonly used)
    final priorityCategories = [
      TaskCategories.chore,
      TaskCategories.grocery,
      TaskCategories.cleaning,
      TaskCategories.laundry,
      TaskCategories.personalCare,
      TaskCategories.homework,
    ];

    // Get all other categories
    final otherCategories = TaskCategories.all
        .where((cat) => !priorityCategories.contains(cat))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(12)),
        
        // Priority categories (most common)
        Wrap(
          spacing: ResponsiveHelper.w(8),
          runSpacing: ResponsiveHelper.h(8),
          children: priorityCategories.map((category) {
            final isSelected = _selectedCategory == category.id;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category.icon,
                    size: ResponsiveHelper.iconSize(16),
                    color: isSelected
                        ? Colors.white
                        : category.color,
                  ),
                  SizedBox(width: ResponsiveHelper.w(6)),
                  Text(category.name),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category.id;
                    // Clear grocery list selection if not grocery category
                    if (category.id != 'grocery') {
                      _selectedGroceryListId = null;
                    }
                  });
                }
              },
              selectedColor: category.color,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : category.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? category.color : category.color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            );
          }).toList(),
        ),
        
        // Show "More Categories" expandable section if there are other categories
        if (otherCategories.isNotEmpty) ...[
          SizedBox(height: ResponsiveHelper.h(12)),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(
              'More Categories',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            children: [
              Wrap(
                spacing: ResponsiveHelper.w(8),
                runSpacing: ResponsiveHelper.h(8),
                children: otherCategories.map((category) {
                  final isSelected = _selectedCategory == category.id;
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          category.icon,
                          size: ResponsiveHelper.iconSize(16),
                          color: isSelected
                              ? Colors.white
                              : category.color,
                        ),
                        SizedBox(width: ResponsiveHelper.w(6)),
                        Text(category.name),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = category.id;
                          // Clear grocery list selection if not grocery category
                          if (category.id != 'grocery') {
                            _selectedGroceryListId = null;
                          }
                        });
                      }
                    },
                    selectedColor: category.color,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : category.color,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? category.color : category.color.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: ResponsiveHelper.h(8)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAssignToSection(
    BuildContext context,
    AsyncValue<List<FamilyMemberModel>> familyMembers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign To',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(12)),
        familyMembers.when(
          data: (members) {
            // If no members, show current user as the only option
            if (members.isEmpty) {
              return Consumer(
                builder: (context, ref, child) {
                  final currentUser = ref.watch(currentUserProvider);
                  if (currentUser == null) {
                    return const Text('No user available');
                  }
                  
                  // Auto-select current user if not already selected
                  if (_selectedAssignee == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedAssignee = currentUser.id;
                        });
                      }
                    });
                  }
                  
                  final avatarUrl = currentUser.avatarUrl;
                  final displayName = currentUser.displayNameOrEmail;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedAssignee = currentUser.id;
                      });
                    },
                    child: Column(
                            children: [
                        Container(
                          width: ResponsiveHelper.w(60),
                          height: ResponsiveHelper.h(60),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: ResponsiveHelper.w(3),
                            ),
                          ),
                          child: AvatarWidget(
                            avatarPath: avatarUrl,
                            radius: ResponsiveHelper.r(28),
                            displayName: displayName,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                                ),
                        SizedBox(height: ResponsiveHelper.h(4)),
                        Text(
                          displayName ?? 'You',
                          style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        );
                },
              );
            }
            
            // Show all members for selection (1 or more)
            // Auto-select first member if none selected
            if (_selectedAssignee == null && members.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _selectedAssignee = members.first.uid;
                  });
                }
              });
            }
            
            return Wrap(
              spacing: ResponsiveHelper.w(16),
              runSpacing: ResponsiveHelper.h(12),
              children: members.map((member) {
                final isSelected = _selectedAssignee == member.uid;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAssignee = member.uid;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveHelper.w(60),
                        height: ResponsiveHelper.h(60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            width: ResponsiveHelper.w(isSelected ? 3 : 2),
                          ),
                        ),
                        child: AvatarWidget(
                          avatarPath: member.photoURL,
                          radius: ResponsiveHelper.r(28),
                          displayName: member.displayName,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        member.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                );
              }).toList(),
            );
          },
          loading: () {
            return const CircularProgressIndicator();
          },
          error: (error, stackTrace) {
            // On error, show current user as fallback
            return Consumer(
              builder: (context, ref, child) {
                final currentUser = ref.watch(currentUserProvider);
                if (currentUser == null) {
                  return Text(
                    'Error loading members',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
                
                // Auto-select current user if not already selected
                if (_selectedAssignee == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedAssignee = currentUser.id;
                      });
                    }
                  });
                }
                
                final avatarUrl = currentUser.avatarUrl;
                final displayName = currentUser.displayNameOrEmail;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAssignee = currentUser.id;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveHelper.w(60),
                        height: ResponsiveHelper.h(60),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: ResponsiveHelper.w(3),
                          ),
                        ),
                        child: AvatarWidget(
                          avatarPath: avatarUrl,
                          radius: ResponsiveHelper.r(28),
                          displayName: displayName,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          textColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        displayName ?? 'You',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    Color getPriorityColor(String priority) {
      switch (priority) {
        case 'high':
          return Colors.red;
        case 'medium':
          return Colors.orange;
        case 'low':
          return Colors.green;
        default:
          return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
      }
    }
    
    IconData getPriorityIcon(String priority) {
      switch (priority) {
        case 'high':
          return Icons.priority_high;
        case 'medium':
          return Icons.remove;
        case 'low':
          return Icons.arrow_downward;
        default:
          return Icons.circle;
      }
    }
    
    String getPriorityLabel(String priority) {
      switch (priority) {
        case 'high':
          return 'High';
        case 'medium':
          return 'Med';
        case 'low':
          return 'Low';
        default:
          return 'Med';
      }
    }
    
    return Row(
      children: [
        Text(
          'Priority:',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: ResponsiveHelper.w(12)),
        Expanded(
          child: Row(
            children: ['low', 'medium', 'high'].map((priority) {
              final isSelected = _selectedPriority == priority;
              final priorityColor = getPriorityColor(priority);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: priority != 'high' ? ResponsiveHelper.w(6) : 0,
                  ),
                  child: Material(
                    color: isSelected
                        ? priorityColor.withOpacity(0.1)
                        : Theme.of(context).cardColor,
                    borderRadius: ResponsiveHelper.borderRadius(8),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedPriority = priority;
                        });
                      },
                      borderRadius: ResponsiveHelper.borderRadius(8),
                      child: Container(
                        padding: ResponsiveHelper.padding(vertical: 8, horizontal: 4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? priorityColor
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            width: ResponsiveHelper.w(isSelected ? 2 : 1),
                          ),
                          borderRadius: ResponsiveHelper.borderRadius(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              getPriorityIcon(priority),
                              size: ResponsiveHelper.iconSize(16),
                              color: isSelected
                                  ? priorityColor
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            SizedBox(width: ResponsiveHelper.w(4)),
                            Text(
                              getPriorityLabel(priority),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? priorityColor
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: ResponsiveHelper.sp(11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDueDateField(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        InkWell(
          onTap: () => _selectDueDate(context),
          child: Container(
            padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              ),
              borderRadius: ResponsiveHelper.borderRadius(12),
            ),
                        child: Row(
                          children: [
                Expanded(
                  child: Text(
                    _selectedDueDate == null
                        ? 'Select date'
                        : DateFormat('MM/dd/yyyy').format(_selectedDueDate!),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                            Icon(
                  Icons.calendar_today,
                  size: ResponsiveHelper.iconSize(20),
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                          ],
                        ),
                      ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        Wrap(
          spacing: ResponsiveHelper.w(8),
          runSpacing: ResponsiveHelper.h(8),
          children: [
            _buildRecurrenceChip(context, 'none', 'None'),
            _buildRecurrenceChip(context, 'daily', 'Daily'),
            _buildRecurrenceChip(context, 'weekly', 'Weekly'),
            _buildRecurrenceChip(context, 'monthly', 'Monthly'),
          ],
        ),
        // Show end date picker if recurrence is not 'none'
        if (_recurrenceType != 'none') ...[
          SizedBox(height: ResponsiveHelper.h(16)),
          Text(
            'Repeat Until',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: ResponsiveHelper.h(8)),
          InkWell(
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              );
              
              if (picked != null) {
                setState(() {
                  _recurrenceEndDate = picked;
                });
              }
            },
            child: Container(
              padding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                ),
                borderRadius: ResponsiveHelper.borderRadius(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _recurrenceEndDate == null
                          ? 'No end date'
                          : DateFormat('MM/dd/yyyy').format(_recurrenceEndDate!),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    size: ResponsiveHelper.iconSize(20),
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrenceChip(BuildContext context, String value, String label) {
    final isSelected = _recurrenceType == value;
    return ActionChip(
      label: Text(label),
      onPressed: () {
        setState(() {
          _recurrenceType = value;
          if (value == 'none') {
            _recurrenceEndDate = null;
          }
        });
      },
      backgroundColor: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: ResponsiveHelper.sp(12),
      ),
      padding: ResponsiveHelper.padding(horizontal: 12, vertical: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildShoppingListSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // If a list is selected, show its name
        if (_selectedGroceryListId != null) {
          final listAsync = ref.watch(groceryListProvider(_selectedGroceryListId!));
          
          return listAsync.when(
            data: (list) {
              if (list == null) {
                return _buildAttachButton(context);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shopping List',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.h(8)),
                  InkWell(
                    onTap: () => _attachShoppingList(context),
                    child: Container(
                      padding: ResponsiveHelper.padding(all: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          style: BorderStyle.solid,
                          width: ResponsiveHelper.w(2),
                        ),
                        borderRadius: ResponsiveHelper.borderRadius(12),
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                        child: Row(
                          children: [
                            Icon(
                            Icons.shopping_cart,
                            color: Theme.of(context).colorScheme.primary,
                            size: ResponsiveHelper.iconSize(24),
                          ),
                          SizedBox(width: ResponsiveHelper.w(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  list.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: ResponsiveHelper.h(4)),
                                Text(
                                  'Tap to change',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              size: ResponsiveHelper.iconSize(20),
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            onPressed: () {
                      setState(() {
                                _selectedGroceryListId = null;
                      });
                    },
                  ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => _buildAttachButton(context),
            error: (_, __) => _buildAttachButton(context),
          );
        }
        
        return _buildAttachButton(context);
      },
    );
  }
  
  Widget _buildAttachButton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shopping List',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        // Create New List Button
                  InkWell(
          onTap: () => _createNewShoppingList(context),
          child: Container(
            padding: ResponsiveHelper.padding(all: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                style: BorderStyle.solid,
                width: ResponsiveHelper.w(2),
              ),
                          borderRadius: ResponsiveHelper.borderRadius(12),
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).colorScheme.secondary,
                  size: ResponsiveHelper.iconSize(24),
                ),
                SizedBox(width: ResponsiveHelper.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create New List',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        'Start a fresh shopping list',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(12)),
        // Attach Existing List Button
        InkWell(
          onTap: () => _attachShoppingList(context),
          child: Container(
            padding: ResponsiveHelper.padding(all: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                style: BorderStyle.solid,
                width: ResponsiveHelper.w(2),
              ),
              borderRadius: ResponsiveHelper.borderRadius(12),
            ),
            child: Row(
                    children: [
                      Icon(
                  Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.primary,
                  size: ResponsiveHelper.iconSize(24),
                ),
                SizedBox(width: ResponsiveHelper.w(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attach Existing List',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        'Use an existing shopping list',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateInfoSection(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        if (_templateIdToImport == null) return const SizedBox.shrink();
        
        final currentFamily = ref.watch(currentFamilyProvider);
        final templates = currentFamily != null
            ? ref.watch(groceryTemplatesProvider(currentFamily.id))
            : const AsyncValue.data(<GroceryTemplateModel>[]);
        
        return templates.when(
          data: (templateList) {
            final template = templateList.firstWhere(
              (t) => t.id == _templateIdToImport,
              orElse: () => GroceryTemplateModel(
                id: _templateIdToImport!,
                familyId: '',
                name: 'Template',
                createdBy: '',
              ),
            );
            
            // Map template name to icon
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
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Template',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                      Container(
                  padding: ResponsiveHelper.padding(all: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: ResponsiveHelper.w(2),
                    ),
                    borderRadius: ResponsiveHelper.borderRadius(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: iconColor,
                        size: ResponsiveHelper.iconSize(24),
                      ),
                      SizedBox(width: ResponsiveHelper.w(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              template.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                            ),
                            SizedBox(height: ResponsiveHelper.h(4)),
                            Text(
                              'Items will be imported from this template',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          size: ResponsiveHelper.iconSize(20),
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                        onPressed: () {
                          setState(() {
                            _templateIdToImport = null;
                          });
                        },
                        tooltip: 'Remove template',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: 'Add any extra details...',
            border: OutlineInputBorder(
              borderRadius: ResponsiveHelper.borderRadius(12),
            ),
            contentPadding: ResponsiveHelper.padding(all: 16),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildTemplateSelector(BuildContext context) {
    final currentFamily = ref.watch(currentFamilyProvider);
    if (currentFamily == null) return const SizedBox.shrink();

    final templatesAsync = ref.watch(taskTemplatesProvider(currentFamily.id));

    return templatesAsync.when(
      data: (templates) {
        if (templates.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use Template (Optional)',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(8)),
            Container(
              height: ResponsiveHelper.h(120),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = _selectedTemplateId == template.id;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTemplateId = null;
                          _titleController.clear();
                          _notesController.clear();
                          _selectedCategory = widget.initialCategory ?? 'chore';
                          _selectedPriority = 'medium';
                          _recurrenceType = 'none';
                          _recurrenceEndDate = null;
                        } else {
                          _selectedTemplateId = template.id;
                          _titleController.text = template.title;
                          _notesController.text = template.description ?? '';
                          _selectedCategory = template.category ?? 'chore';
                          _selectedPriority = template.priority ?? 'medium';
                          _recurrenceType = template.recurrenceType ?? 'none';
                          _recurrenceEndDate = template.recurrenceEndDate;
                        }
                      });
                    },
                    child: Container(
                      width: ResponsiveHelper.w(140),
                      margin: EdgeInsets.only(right: ResponsiveHelper.w(12)),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          width: isSelected ? ResponsiveHelper.w(2) : ResponsiveHelper.w(1),
                        ),
                        borderRadius: ResponsiveHelper.borderRadius(12),
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      padding: ResponsiveHelper.padding(all: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: ResponsiveHelper.iconSize(24),
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          SizedBox(height: ResponsiveHelper.h(8)),
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Dialog widget for creating a new shopping list from task creation
class _CreateShoppingListDialog extends StatefulWidget {
  final String userId;
  final FamilyModel currentFamily;
  final GroceryListRepository listRepo;
  final GroceryTemplateRepository templateRepo;
  final AsyncValue<List<GroceryTemplateModel>> templatesAsync;

  const _CreateShoppingListDialog({
    required this.userId,
    required this.currentFamily,
    required this.listRepo,
    required this.templateRepo,
    required this.templatesAsync,
  });

  @override
  State<_CreateShoppingListDialog> createState() => _CreateShoppingListDialogState();
}

class _CreateShoppingListDialogState extends State<_CreateShoppingListDialog> {
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
        'Create New Shopping List',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.h(8)),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Weekly Shopping',
                    border: OutlineInputBorder(
                          borderRadius: ResponsiveHelper.borderRadius(12),
                        ),
                    contentPadding: ResponsiveHelper.padding(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a list name';
                    }
                    return null;
                  },
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
                    // Create a standalone list
                    final newList = await widget.listRepo.createStandaloneList(
                      familyId: widget.currentFamily.id,
                      name: _nameController.text.trim(),
                      templateId: _selectedTemplateId,
                      createdBy: widget.userId,
                    );

                    // If template selected, import items (do NOT copy notes, skip duplicates)
                    if (_selectedTemplateId != null && _selectedTemplateId!.isNotEmpty) {
                      final templateItems = await widget.templateRepo.getTemplateItems(_selectedTemplateId!);
                      
                      // Get existing items to check for duplicates
                      final existingItems = await widget.listRepo.getListItems(newList.id);
                      final existingItemKeys = existingItems
                          .map((item) => '${item.name.toLowerCase()}_${item.category.toLowerCase()}')
                          .toSet();
                      
                      // Filter out duplicates
                      final itemsToImport = templateItems.where((templateItem) {
                        final key = '${templateItem.name.toLowerCase()}_${templateItem.category.toLowerCase()}';
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
                      Navigator.of(context).pop(newList.id);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to create list: ${e.toString().replaceAll('Exception: ', '')}'),
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
          return const SizedBox.shrink();
        }
        
        return Container(
          constraints: BoxConstraints(
            maxHeight: ResponsiveHelper.h(200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: templates.length,
            separatorBuilder: (context, index) => SizedBox(height: ResponsiveHelper.h(8)),
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
                        : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: ResponsiveHelper.borderRadius(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                      width: isSelected ? ResponsiveHelper.w(2) : ResponsiveHelper.w(1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        size: ResponsiveHelper.iconSize(20),
                      ),
                      SizedBox(width: ResponsiveHelper.w(12)),
                      Expanded(
                        child: Text(
                          template.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
