import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class EditTaskPage extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskPage({
    super.key,
    required this.task,
  });

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  
  String? _selectedAssignee;
  String _selectedCategory = 'chore';
  DateTime? _selectedDueDate;
  String? _selectedGroceryListId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(text: widget.task.description ?? '');
    _selectedAssignee = widget.task.assignedTo;
    _selectedCategory = widget.task.category;
    _selectedDueDate = widget.task.dueDate;
    _selectedGroceryListId = widget.task.categoryData?['groceryListId'] as String?;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // If task is completed, prevent editing and navigate back
    if (widget.task.status == 'completed') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot edit completed tasks. Please unmark the task as complete first.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          context.pop();
        }
      });
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
      final currentFamily = ref.read(currentFamilyProvider);
      
      if (currentFamily == null) {
        throw Exception('No family selected');
      }

      final taskActions = ref.read(taskActionsProvider);
      
      // Update task
      await taskActions.updateTask(
        taskId: widget.task.id,
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty 
            ? null 
            : _notesController.text.trim(),
        assignedTo: assignee,
        category: _selectedCategory,
        categoryData: _selectedGroceryListId != null
            ? {'groceryListId': _selectedGroceryListId}
            : null,
        dueDate: _selectedDueDate,
      );
      
      // Refresh the tasks list to show the updated task immediately
      ref.invalidate(familyTasksProvider(currentFamily.id));
      ref.invalidate(tasksDueTodayProvider(currentFamily.id));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Chore updated successfully!'),
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
            content: Text('Failed to update chore: ${e.toString()}'),
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
                        
                        // Shopping List (only if grocery category)
                        if (_selectedCategory == 'grocery') ...[
                          _buildShoppingListSection(context),
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
              'Edit Chore',
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
            // If no members, show current user as the only option
            if (members.isEmpty) {
              return Consumer(
                builder: (context, ref, child) {
                  final currentUser = ref.watch(currentUserProvider);
                  if (currentUser == null) {
                    return const Text('No user available');
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
            
            // Show all members for selection
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
          loading: () => const CircularProgressIndicator(),
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

