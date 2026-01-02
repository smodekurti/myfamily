import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../common/responsive/responsive_helper.dart'; // Corrected path
import '../../../../data/models/meal_plan_model.dart';

class MealSlotEditPage extends ConsumerStatefulWidget {
  final String familyId;
  final String planId;
  final DateTime date;
  final String mealType;
  final MealPlanEntryModel? existingEntry;

  const MealSlotEditPage({
    super.key,
    required this.familyId,
    required this.planId,
    required this.date,
    required this.mealType,
    this.existingEntry,
  });

  @override
  ConsumerState<MealSlotEditPage> createState() => _MealSlotEditPageState();
}

class _MealSlotEditPageState extends ConsumerState<MealSlotEditPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _noteController = TextEditingController();
  String? _selectedRecipeId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Initialize state from existing entry
    if (widget.existingEntry != null) {
      if (widget.existingEntry!.recipeId != null) {
        _selectedRecipeId = widget.existingEntry!.recipeId;
      } else {
        _tabController.index = 1; // Switch to Custom Note tab
        _noteController.text = widget.existingEntry!.customNote ?? '';
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);

    try {
      final isRecipeMode = _tabController.index == 0;

      final planId = widget.planId == 'auto' ? '' : widget.planId;
      final entry = MealPlanEntryModel(
        id: widget.existingEntry?.id ?? '', // Empty ID means create new
        planId: planId,
        mealDate: widget.date,
        mealType: widget.mealType.toLowerCase(),
        recipeId: isRecipeMode ? _selectedRecipeId : null,
        customNote: !isRecipeMode ? _noteController.text.trim() : null,
        isCompleted: widget.existingEntry?.isCompleted ?? false,
      );

      await ref
          .read(mealPlanRepositoryProvider)
          .saveEntryForFamily(widget.familyId, entry);

      // Refresh providers
      // Invalidate all rolling views to be safe since we don't know the exact window start the user is viewing
      ref.invalidate(rollingMealPlanEntriesProvider);
      ref.invalidate(currentWeekMealPlanProvider(widget.familyId));

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal slot updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(familyRecipesProvider(widget.familyId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.mealType} - ${DateFormat('MMM d').format(widget.date)}',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Select Recipe'),
            Tab(text: 'Custom Note'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Recipe Selection Tab
          recipesAsync.when(
            data: (recipes) {
              if (recipes.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'No recipes found',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 16.h),
                      FilledButton.icon(
                        onPressed: () {
                          context.push(AppConstants.routeCreateRecipe);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Recipe'),
                      ),
                      TextButton(
                        onPressed: () {
                          // Allow switching to Custom Note tab as alternative
                          _tabController.animateTo(1);
                        },
                        child: const Text('Or add a Custom Note'),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: ResponsiveHelper.padding(all: 16),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  final isSelected = _selectedRecipeId == recipe.id;

                  return InkWell(
                    onTap: () => setState(() => _selectedRecipeId = recipe.id),
                    borderRadius: BorderRadius.circular(12.r),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          if (!isSelected)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          if (recipe.imageUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.network(
                                recipe.imageUrl!,
                                width: 50.w,
                                height: 50.w,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50.w,
                                  height: 50.w,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.restaurant,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.grey,
                              ),
                            ),

                          SizedBox(width: 16.w),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                if (recipe.description != null)
                                  Text(
                                    recipe.description!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.grey,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    maxLines: 1,
                                  ),
                              ],
                            ),
                          ),

                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppTheme.primaryColor,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err')),
          ),

          // Custom Note Tab
          SingleChildScrollView(
            padding: ResponsiveHelper.padding(all: 16),
            child: Column(
              children: [
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Meal Description',
                    hintText: 'e.g., Eating Out, Leftovers, Pizza Night',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 16.h),
                const Text(
                  'Use this for meals that don\'t have a specific recipe card, like dining out or quick snacks.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: ResponsiveHelper.padding(all: 16),
          child: FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? SizedBox(
                    width: 20.h,
                    height: 20.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save Meal'),
          ),
        ),
      ),
    );
  }
}
