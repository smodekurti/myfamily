import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/grocery_template_model.dart';
import '../../../groceries/presentation/pages/grocery_list_page.dart'; // For groceryTemplatesProvider
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
  DateTime? _selectedDueDate;
  String? _selectedGroceryListId;
  String? _templateIdToImport;
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
    if (_selectedCategory == 'grocery' && templateId != null && _templateIdToImport == null) {
      _templateIdToImport = templateId;
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
      
      // Create task
      final task = await taskActions.createTask(
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        assignedTo: assignee,
        createdBy: currentUser.id,
        familyId: currentFamily.id,
        category: _selectedCategory,
        categoryData: _selectedGroceryListId != null
            ? {'groceryListId': _selectedGroceryListId}
            : null,
        dueDate: _selectedDueDate,
      );

      // If grocery category, handle grocery list
      if (_selectedCategory == 'grocery') {
        final groceryListRepo = ref.read(groceryListRepositoryProvider);
        String groceryListId;
        
        // If an existing shopping list was selected, link it to the task
        if (_selectedGroceryListId != null) {
          // Link the existing list to this task
          await groceryListRepo.updateListTaskId(
            listId: _selectedGroceryListId!,
            taskId: task.id,
          );
          groceryListId = _selectedGroceryListId!;
        } else {
          // Create a new grocery list for the task
          final groceryList = await groceryListRepo.createList(
            taskId: task.id,
            familyId: currentFamily.id,
            name: _titleController.text.trim(),
            createdBy: currentUser.id,
            templateId: _templateIdToImport, // Only set if importing from template
          );
          groceryListId = groceryList.id;
          
          // Get existing items to check for duplicates
          final existingItems = await groceryListRepo.getListItems(groceryList.id);
          final existingItemKeys = existingItems
              .map((item) => '${item.name.toLowerCase()}_${item.category.toLowerCase()}')
              .toSet();
          
          // If template was selected, import items from template (skip duplicates)
          if (_templateIdToImport != null) {
            final templateRepo = ref.read(groceryTemplateRepositoryProvider);
            final templateItems = await templateRepo.getTemplateItems(_templateIdToImport!);
            
            // Filter out duplicates
            final itemsToImport = templateItems.where((templateItem) {
              final key = '${templateItem.name.toLowerCase()}_${templateItem.category.toLowerCase()}';
              return !existingItemKeys.contains(key);
            }).toList();
            
            // Add each new template item to the grocery list
            for (final templateItem in itemsToImport) {
              await groceryListRepo.addItem(
                listId: groceryList.id,
                name: templateItem.name,
                category: templateItem.category,
                qty: templateItem.defaultQty,
                notes: templateItem.notes,
                unit: templateItem.unit,
                source: 'template',
              );
            }
          }
        }
        
        // Update task with grocery list ID
        await taskActions.updateTask(
          taskId: task.id,
          categoryData: {'groceryListId': groceryListId},
        );
      }
      
      // Refresh the tasks list to show the new task immediately
      // The stream should update automatically, but this ensures it happens
      // Invalidate both providers to ensure home screen updates
      ref.invalidate(familyTasksProvider(currentFamily.id));
      ref.invalidate(tasksDueTodayProvider(currentFamily.id));
      
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
                        // Chore Name
                        _buildChoreNameField(),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Category selector
                        _buildCategorySelector(),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Assign To
                        _buildAssignToSection(context, familyMembers),
                        SizedBox(height: ResponsiveHelper.h(24)),
                        
                        // Due Date
                        _buildDueDateField(context),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(8)),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Chore'),
                selected: _selectedCategory == 'chore',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = 'chore';
                      _selectedGroceryListId = null;
                    });
                  }
                },
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(12)),
            Expanded(
              child: ChoiceChip(
                label: const Text('Grocery'),
                selected: _selectedCategory == 'grocery',
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedCategory = 'grocery';
                    });
                  }
                },
              ),
            ),
          ],
        ),
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
            debugPrint('👥 CreateTask: Got ${members.length} family members');
            // If no members, show current user as the only option
            if (members.isEmpty) {
              debugPrint('👥 CreateTask: No members found, showing current user only');
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
                          child: CircleAvatar(
                            radius: ResponsiveHelper.r(28),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(
                                    displayName?.substring(0, 1).toUpperCase() ?? '?',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: ResponsiveHelper.sp(20),
                                    ),
                                  )
                                : null,
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
            debugPrint('👥 CreateTask: Showing ${members.length} members for selection');
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
                debugPrint('👥 CreateTask: Member ${member.uid}, displayName: ${member.displayName}, photoURL: ${member.photoURL}, isSelected: $isSelected');
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
                        child: CircleAvatar(
                          radius: ResponsiveHelper.r(28),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: member.photoURL != null
                              ? NetworkImage(member.photoURL!)
                              : null,
                          child: member.photoURL == null
                              ? Text(
                                  member.displayName.isNotEmpty
                                      ? member.displayName.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.sp(20),
                                  ),
                                )
                              : null,
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
            debugPrint('👥 CreateTask: Family members loading...');
            return const CircularProgressIndicator();
          },
          error: (error, stackTrace) {
            debugPrint('👥 CreateTask: Error loading family members: $error');
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
                        child: CircleAvatar(
                          radius: ResponsiveHelper.r(28),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          backgroundImage: avatarUrl != null
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null
                              ? Text(
                                  displayName?.substring(0, 1).toUpperCase() ?? '?',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: ResponsiveHelper.sp(20),
                                  ),
                                )
                              : null,
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
                        'Attach Shopping List',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(
                        'Add items from an existing list',
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
}
