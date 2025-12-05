import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/providers/providers.dart';

import '../../../../core/models/task_category.dart';
import '../../../../data/models/family_model.dart';
import '../../../../data/models/task_model.dart';
import 'package:intl/intl.dart';

class EditTaskPage extends ConsumerStatefulWidget {
  final TaskModel task;

  const EditTaskPage({super.key, required this.task});

  @override
  ConsumerState<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends ConsumerState<EditTaskPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;

  String? _selectedAssignee;
  String _selectedCategory = 'chore';
  String _selectedPriority = 'medium';
  DateTime? _selectedDueDate;
  String? _selectedGroceryListId;
  String _recurrenceType = 'none'; // 'none', 'daily', 'weekly', 'monthly'
  DateTime? _recurrenceEndDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _notesController = TextEditingController(
      text: widget.task.description ?? '',
    );
    _selectedAssignee = widget.task.assignedTo;
    _selectedCategory = widget.task.category;
    _selectedPriority = widget.task.priority;
    _selectedDueDate = widget.task.dueDate;
    _selectedGroceryListId =
        widget.task.categoryData?['groceryListId'] as String?;
    _recurrenceType =
        widget.task.categoryData?['recurrenceType'] as String? ?? 'none';
    if (widget.task.categoryData?['recurrenceEndDate'] != null) {
      _recurrenceEndDate = DateTime.parse(
        widget.task.categoryData!['recurrenceEndDate'] as String,
      );
    }
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
              content: const Text(
                'Cannot edit completed tasks. Please unmark the task as complete first.',
              ),
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
    final now = DateTime.now();
    // Allow dates from 2 years ago to 5 years in the future
    final firstDate = DateTime(now.year - 2);
    final lastDate = DateTime(now.year + 5);

    // Ensure initial date is within range
    DateTime initialDate = _selectedDueDate ?? now;
    if (initialDate.isBefore(firstDate)) initialDate = firstDate;
    if (initialDate.isAfter(lastDate)) initialDate = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
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

      // Build categoryData with recurrence and grocery list info
      Map<String, dynamic>? categoryData;
      if (_recurrenceType != 'none' || _selectedGroceryListId != null) {
        categoryData = Map<String, dynamic>.from(
          widget.task.categoryData ?? {},
        );
        if (_recurrenceType != 'none') {
          categoryData['recurrenceType'] = _recurrenceType;
          if (_recurrenceEndDate != null) {
            categoryData['recurrenceEndDate'] = _recurrenceEndDate!
                .toIso8601String();
          } else {
            categoryData.remove('recurrenceEndDate');
          }
        } else {
          categoryData.remove('recurrenceType');
          categoryData.remove('recurrenceEndDate');
        }
        if (_selectedGroceryListId != null) {
          categoryData['groceryListId'] = _selectedGroceryListId;
        } else if (_selectedCategory != 'grocery') {
          categoryData.remove('groceryListId');
        }
        // If categoryData becomes empty, pass empty map to clear it in database
        if (categoryData.isEmpty) {
          categoryData = {};
        }
      } else {
        // Clear categoryData if no recurrence and no grocery list
        // Pass empty map to explicitly clear it in database
        categoryData = {};
      }

      // Update task
      await taskActions.updateTask(
        taskId: widget.task.id,
        title: _titleController.text.trim(),
        description: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        assignedTo: assignee,
        category: _selectedCategory,
        priority: _selectedPriority,
        categoryData: categoryData,
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
        if (mounted && context.mounted) {
          context.pop();
        }
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: ResponsiveHelper.h(24)), // Top spacing
            Expanded(
              child: SingleChildScrollView(
                padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleField(),
                      SizedBox(height: ResponsiveHelper.h(32)),

                      _buildCategorySelector(),
                      SizedBox(height: ResponsiveHelper.h(32)),

                      _buildPropertiesGrid(context, familyMembers),
                      SizedBox(height: ResponsiveHelper.h(32)),

                      _buildSettingsSection(context),
                      SizedBox(height: ResponsiveHelper.h(32)),

                      _buildNotesField(),
                      SizedBox(height: ResponsiveHelper.h(32)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: ResponsiveHelper.padding(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    padding: ResponsiveHelper.padding(vertical: 16),
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveHelper.borderRadius(16),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.sp(16),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveHelper.w(16)),
              Expanded(
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveTask,
                  style: FilledButton.styleFrom(
                    padding: ResponsiveHelper.padding(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: ResponsiveHelper.borderRadius(16),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: ResponsiveHelper.w(24),
                          height: ResponsiveHelper.h(24),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.sp(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'What needs to be done?',
        hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a task name';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelector() {
    // Combine all categories
    final allCategories = [...TaskCategories.all];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: allCategories.map((category) {
              final isSelected = _selectedCategory == category.id;
              return Padding(
                padding: EdgeInsets.only(right: ResponsiveHelper.w(16)),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category.id;
                      if (category.id != 'grocery') {
                        _selectedGroceryListId = null;
                      }
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: ResponsiveHelper.w(64),
                        height: ResponsiveHelper.h(64),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? category.color
                              : category.color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: category.color.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Icon(
                          category.icon,
                          color: isSelected ? Colors.white : category.color,
                          size: ResponsiveHelper.iconSize(28),
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(8)),
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPropertiesGrid(
    BuildContext context,
    AsyncValue<List<FamilyMemberModel>> familyMembers,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DETAILS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Due Date Tile
            Expanded(
              child: _buildPropertyTile(
                icon: Icons.calendar_today,
                color: Colors.blue,
                label: 'Due Date',
                value: _selectedDueDate == null
                    ? 'Set Date'
                    : DateFormat('MMM d').format(_selectedDueDate!),
                onTap: () => _selectDueDate(context),
                isActive: _selectedDueDate != null,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(12)),

            // Priority Tile
            Expanded(
              child: _buildPropertyTile(
                icon: _getPriorityIcon(_selectedPriority),
                color: _getPriorityColor(_selectedPriority),
                label: 'Priority',
                value: _selectedPriority.toUpperCase(),
                onTap: () {
                  // Cycle priority
                  setState(() {
                    if (_selectedPriority == 'low') {
                      _selectedPriority = 'medium';
                    } else if (_selectedPriority == 'medium') {
                      _selectedPriority = 'high';
                    } else {
                      _selectedPriority = 'low';
                    }
                  });
                },
                isActive: true,
              ),
            ),
            SizedBox(width: ResponsiveHelper.w(12)),

            // Assignee Tile
            Expanded(
              child: familyMembers.when(
                data: (members) {
                  final assignedMember = members.firstWhere(
                    (m) => m.uid == _selectedAssignee,
                    orElse: () => members.firstWhere(
                      (m) => m.uid == ref.read(currentUserProvider)?.id,
                      orElse: () => members.first,
                    ),
                  );

                  return _buildPropertyTile(
                    icon: Icons.person_outline,
                    color: Colors.purple,
                    label: 'Assignee',
                    value: assignedMember.displayName.split(' ').first,
                    onTap: () => _showAssigneePicker(context, members),
                    isActive: true,
                    customIcon: AvatarWidget(
                      avatarPath: assignedMember.photoURL,
                      radius: ResponsiveHelper.r(12),
                      displayName: assignedMember.displayName,
                      backgroundColor: Colors.purple,
                      textColor: Colors.white,
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyTile({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isActive,
    Widget? customIcon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveHelper.padding(all: 12),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: ResponsiveHelper.borderRadius(16),
          border: Border.all(
            color: isActive ? color.withValues(alpha: 0.3) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: ResponsiveHelper.padding(all: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ],
              ),
              child:
                  customIcon ??
                  Icon(icon, size: ResponsiveHelper.iconSize(16), color: color),
            ),
            SizedBox(height: ResponsiveHelper.h(12)),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: ResponsiveHelper.h(4)),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SETTINGS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: ResponsiveHelper.borderRadius(16),
          ),
          child: Column(
            children: [
              // Recurrence Tile
              ListTile(
                leading: Container(
                  padding: ResponsiveHelper.padding(all: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: ResponsiveHelper.borderRadius(8),
                  ),
                  child: Icon(
                    Icons.repeat,
                    color: Colors.orange,
                    size: ResponsiveHelper.iconSize(20),
                  ),
                ),
                title: const Text('Repeat'),
                subtitle: Text(
                  _recurrenceType == 'none'
                      ? 'Does not repeat'
                      : _recurrenceType.capitalize(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRecurrencePicker(context),
              ),

              if (_selectedCategory == 'grocery') ...[
                Padding(
                  padding: ResponsiveHelper.padding(horizontal: 16),
                  child: Divider(
                    height: 1,
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: ResponsiveHelper.padding(all: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: ResponsiveHelper.borderRadius(8),
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Colors.green,
                      size: ResponsiveHelper.iconSize(20),
                    ),
                  ),
                  title: const Text('Shopping List'),
                  subtitle: const Text('Attach items'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _attachShoppingList(context),
                ),
              ],
            ],
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
          'NOTES',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        SizedBox(height: ResponsiveHelper.h(16)),
        Container(
          padding: ResponsiveHelper.padding(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: ResponsiveHelper.borderRadius(16),
          ),
          child: TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add any extra details...',
              border: InputBorder.none,
            ),
            maxLines: 4,
            minLines: 2,
          ),
        ),
      ],
    );
  }

  // Helper methods

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getPriorityIcon(String priority) {
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

  Future<void> _showAssigneePicker(
    BuildContext context,
    List<FamilyMemberModel> members,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: ResponsiveHelper.padding(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Assign To',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            Wrap(
              spacing: ResponsiveHelper.w(16),
              runSpacing: ResponsiveHelper.h(16),
              children: members.map((member) {
                final isSelected = _selectedAssignee == member.uid;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedAssignee = member.uid);
                    context.pop();
                  },
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: AvatarWidget(
                          avatarPath: member.photoURL,
                          radius: ResponsiveHelper.r(30),
                          displayName: member.displayName,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.h(4)),
                      Text(member.displayName.split(' ').first),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showRecurrencePicker(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: ResponsiveHelper.padding(all: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Repeat Task',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: ResponsiveHelper.h(16)),
            ...['none', 'daily', 'weekly', 'monthly'].map(
              (type) => ListTile(
                title: Text(
                  type == 'none' ? 'Does not repeat' : type.capitalize(),
                ),
                trailing: _recurrenceType == type
                    ? Icon(Icons.check, color: Theme.of(context).primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _recurrenceType = type;
                    if (type == 'none') _recurrenceEndDate = null;
                  });
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
