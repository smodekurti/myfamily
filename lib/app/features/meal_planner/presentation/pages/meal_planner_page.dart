import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/providers.dart';
import '../../../../core/extensions/user_extensions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../common/widgets/avatar_widget.dart';
import '../../../../common/responsive/responsive_helper.dart';
import '../../../../core/services/gemini_service.dart';
import '../../../../data/models/meal_plan_model.dart';

class MealPlannerPage extends ConsumerStatefulWidget {
  const MealPlannerPage({super.key});

  @override
  ConsumerState<MealPlannerPage> createState() => _MealPlannerPageState();
}

class _MealPlannerPageState extends ConsumerState<MealPlannerPage> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To use Magic Plan, you need a free Google Gemini API Key. The key is stored securely on your device.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Don\'t have a key?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(
                  'https://aistudio.google.com/app/apikey',
                );
                if (!await launchUrl(url)) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not launch URL')),
                    );
                  }
                }
              },
              child: const Text(
                'Get a free API Key here ↗',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Paste API Key',
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save Key'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await ref.read(geminiServiceProvider).setApiKey(result);
      if (mounted) _handleMagicPlan();
    }
  }

  Future<void> _handleMagicPlan() async {
    final gemini = ref.read(geminiServiceProvider);
    final hasKey = await gemini.hasApiKey();

    if (!hasKey) {
      if (mounted) _showApiKeyDialog();
      return;
    }

    if (!mounted) return;

    // Show Preferences Dialog
    final selectedTags = await _showPreferencesDialog();
    if (selectedTags == null) return; // User cancelled

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final plan = await gemini.generateMealPlan(
        days: 7,
        dietaryTags: selectedTags,
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        _showPlanPreview(plan);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<List<String>?> _showPreferencesDialog([
    List<String>? initialSelection,
  ]) async {
    final List<String> options = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'Kid-Friendly',
      'Healthy',
      'Low-Carb',
    ];

    // Default selection
    List<String> selected = List.from(initialSelection ?? []);

    return await showDialog<List<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Magic Plan Options'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select dietary requirements and preferences:'),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final isSelected = selected.contains(option);
                    return FilterChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (bool value) {
                        setState(() {
                          if (value) {
                            selected.add(option);
                          } else {
                            selected.remove(option);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, selected),
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPlanPreview(List<Map<String, dynamic>> generatedPlan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Magic Plan Preview'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: generatedPlan.length,
            itemBuilder: (context, index) {
              final day = generatedPlan[index];
              final meals = (day['meals'] as List).cast<Map<String, dynamic>>();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${index + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...meals.map(
                    (meal) => ListTile(
                      title: Text(meal['name']),
                      subtitle: Text(
                        '${meal['type']} - ${meal['description']}',
                      ),
                      dense: true,
                    ),
                  ),
                  const Divider(),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _saveGeneratedPlan(generatedPlan);
            },
            child: const Text('Apply Plan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMagicPlanOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Magic Plan 🪄'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'week'),
            child: const ListTile(
              leading: Icon(Icons.date_range),
              title: Text('Plan Entire Week'),
              subtitle: Text('Generate meals for the next 7 days'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'day'),
            child: const ListTile(
              leading: Icon(Icons.today),
              title: Text('Plan Selected Day'),
              subtitle: Text('Generate meals just for this day'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'meal'),
            child: const ListTile(
              leading: Icon(Icons.restaurant),
              title: Text('Plan Single Meal'),
              subtitle: Text('Generate one specific meal'),
            ),
          ),
        ],
      ),
    );

    if (option == null) return;

    if (option == 'week') {
      await _generateFullWeekPlan();
    } else if (option == 'day') {
      await _generateDayPlan();
    } else if (option == 'meal') {
      await _generateSingleMeal();
    }
  }

  Future<void> _generateFullWeekPlan() async {
    final currentUser = ref.read(currentUserProvider);
    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentUser == null || currentFamilyId == null) return;

    // 1. Get Preferences
    final currentPrefs =
        (currentUser.userMetadata?['dietary_preferences'] as List?)
            ?.cast<String>() ??
        [];
    final selectedTags = await _showPreferencesDialog(currentPrefs);
    if (selectedTags == null) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Designing your weekly menu...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final hasKey = await geminiService.hasApiKey();

      if (!hasKey) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          _showApiKeyDialog();
        }
        return;
      }

      // Generate plan for 7 days
      final planData = await geminiService.generateMealPlan(
        days: 7,
        dietaryTags: selectedTags,
      );

      // Save to database
      final planRepo = ref.read(mealPlanRepositoryProvider);
      final now = DateTime.now();

      // Create or update plan
      // For simplicity, we'll create a new plan starting today if one doesn't exist for this week
      // Or we could update the existing one.
      // Let's use the current week's plan ID if available, or create new.
      final currentPlanAsync = ref.read(
        currentWeekMealPlanProvider(currentFamilyId),
      );
      // We can't easily get the value from AsyncValue here without listening.
      // So detailed logic: fetch current plan for start date.
      // For this MVP, let's just create entries linked to the family.
      // We need a plan ID.
      String planId;
      final existingPlan =
          currentPlanAsync.value; // Might be null if not loaded
      if (existingPlan == null) {
        // Create new
        final created = await ref
            .read(mealPlanRepositoryProvider)
            .getOrCreateWeeklyPlan(currentFamilyId, DateTime.now());
        planId = created.id;
      } else {
        planId = existingPlan.id;
      }
      for (int i = 0; i < planData.length; i++) {
        final dayData = planData[i];
        final date = now.add(Duration(days: i));
        final meals = dayData['meals'] as List;

        for (final meal in meals) {
          final type = (meal['type'] as String).toLowerCase();
          final entry = MealPlanEntryModel(
            id: '', // New entry
            planId: planId,
            mealDate: date,
            mealType: type,
            customNote: '${meal['name']}: ${meal['description']}',
            isCompleted: false,
          );
          await planRepo.saveMealEntry(entry);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ref.invalidate(currentWeekMealPlanProvider(currentFamilyId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Weekly plan generated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _generateDayPlan() async {
    final currentUser = ref.read(currentUserProvider);
    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentUser == null || currentFamilyId == null) return;

    // 1. Get Preferences
    final currentPrefs =
        (currentUser.userMetadata?['dietary_preferences'] as List?)
            ?.cast<String>() ??
        [];
    final selectedTags = await _showPreferencesDialog(currentPrefs);
    if (selectedTags == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Planning your day...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final hasKey = await geminiService.hasApiKey();

      if (!hasKey) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showApiKeyDialog();
        }
        return;
      }

      // Generate for 1 day
      final planData = await geminiService.generateMealPlan(
        days: 1,
        dietaryTags: selectedTags,
      );

      if (planData.isEmpty) throw Exception('No plan generated');

      // Get or create plan for this week (based on selected date)
      // Find start of week for selected date?
      // Actually getOrCreateWeeklyPlan usually takes "today" to find current plan.
      // But we want to modify the plan that *contains* _selectedDate.
      // If we are viewing a future week, we should likely be passing that week's start.
      // For now, let's stick to modifying the currently loaded plan or creating one if missing.
      final planRepo = ref.read(mealPlanRepositoryProvider);

      // Helper to find start of week (assuming Monday start? Or just rely on repo logic?)
      // Repo logic seems to take a date and normalize it.
      // Let's pass _selectedDate, repo will find/create plan for that week.
      // Wait, getOrCreateWeeklyPlan documentation says "for a specific week (start date)".
      // It normalizes to start of day. It doesn't auto-snap to Monday.
      // If our app logic assumes plans start on specific days, we might create multiple plans.
      // Let's assume for now we just use _selectedDate and let backend handle it,
      // or better: use the existing ID from the provider if we have one.

      String planId = '';
      MealPlanModel? plan;

      final currentPlan = ref
          .read(currentWeekMealPlanProvider(currentFamilyId))
          .value;
      if (currentPlan != null &&
          !_selectedDate.isBefore(currentPlan.startDate) &&
          !_selectedDate.isAfter(currentPlan.endDate)) {
        planId = currentPlan.id;
        plan = currentPlan;
      } else {
        // We are on a different week or no plan loaded.
        // Create/Get plan starting at _selectedDate (or its week start).
        // For safety, let's just use _selectedDate.
        plan = await planRepo.getOrCreateWeeklyPlan(
          currentFamilyId,
          _selectedDate,
        );
        planId = plan.id;
      }

      // Map Day 1 to _selectedDate
      final dayData = planData.first;
      final meals = dayData['meals'] as List;

      for (final meal in meals) {
        final type = (meal['type'] as String).toLowerCase();

        final existingEntry = plan.entries
            ?.cast<MealPlanEntryModel?>()
            .firstWhere(
              (e) =>
                  DateUtils.isSameDay(e?.mealDate, _selectedDate) &&
                  e?.mealType.toLowerCase() == type,
              orElse: () => null,
            );

        final entry = MealPlanEntryModel(
          id: existingEntry?.id ?? '',
          planId: planId,
          mealDate: _selectedDate,
          mealType: type,
          customNote: '${meal['name']}: ${meal['description']}',
          isCompleted: false,
          recipeId: null,
        );

        await planRepo.saveMealEntry(entry);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ref.invalidate(currentWeekMealPlanProvider(currentFamilyId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Day plan updated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _handleAddToShoppingList() async {
    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentFamilyId == null) return;

    final plan = ref.read(currentWeekMealPlanProvider(currentFamilyId)).value;

    if (plan == null || (plan.entries?.isEmpty ?? true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No meal plan found to generate list from.'),
        ),
      );
      return;
    }

    // Ask for scope
    final scope = await _showScopeSelectionDialog();
    if (scope == null) return; // User cancelled

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing menu for ingredients...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final geminiService = ref.read(geminiServiceProvider);

      // Prepare plan data for Gemini
      final planData = <Map<String, dynamic>>[];

      // Filter entries based on scope
      final allEntries = plan.entries!.cast<MealPlanEntryModel>();
      final List<MealPlanEntryModel> scopedEntries;

      switch (scope) {
        case ShoppingListScope.week:
          scopedEntries = allEntries;
          break;
        case ShoppingListScope.day:
          scopedEntries = allEntries
              .where((e) => DateUtils.isSameDay(e.mealDate, _selectedDate))
              .toList();
          break;
        default:
          scopedEntries = [];
      }

      if (scopedEntries.isEmpty) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No meals found for selected range.')),
          );
        }
        return;
      }

      // Group by date
      final Map<DateTime, List<MealPlanEntryModel>> byDate = {};
      for (final e in scopedEntries) {
        final date = DateUtils.dateOnly(e.mealDate);
        if (!byDate.containsKey(date)) byDate[date] = [];
        byDate[date]!.add(e);
      }

      final sortedDates = byDate.keys.toList()..sort();
      for (final date in sortedDates) {
        planData.add({
          'day': '${date.month}/${date.day}',
          'meals': byDate[date]!
              .map(
                (e) => {
                  'name': e.mealType
                      .toUpperCase(), // Using type as name if recipe generic, or customNote
                  'description': e.customNote,
                },
              )
              .toList(),
        });
      }

      final ingredients = await geminiService.extractIngredientsFromPlan(
        planData,
      );

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading

        if (ingredients.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ingredients could be extracted.')),
          );
          return;
        }

        // Ask where to add
        // Determine default list name
        final timestamp = DateTime.now();
        final listName =
            'Meal Plan Shopping (${timestamp.month}/${timestamp.day})';
        await _showAddToListDialog(ingredients, listName);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<ShoppingListScope?> _showScopeSelectionDialog() async {
    return await showDialog<ShoppingListScope>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Generate Shopping List For...'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ShoppingListScope.week);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text('Enter Week'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, ShoppingListScope.day);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Selected Day Only (${_selectedDate.month}/${_selectedDate.day})',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddToListDialog(
    List<Map<String, dynamic>> ingredients,
    String listName,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Found ${ingredients.length} items'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ready to add ${ingredients.length} ingredients to "$listName".',
              ),
              const SizedBox(height: 16),
              // Preview a few
              Wrap(
                spacing: 8,
                children: ingredients
                    .take(5)
                    .map(
                      (e) => Chip(
                        label: Text(e['name']),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
              if (ingredients.length > 5)
                Text('+ ${(ingredients.length - 5)} more...'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _addItemsToNewList(ingredients, listName);
            },
            child: const Text('Add to List'),
          ),
        ],
      ),
    );
  }

  Future<void> _addItemsToNewList(
    List<Map<String, dynamic>> items,
    String listName,
  ) async {
    final currentUser = ref.read(currentUserProvider);
    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentUser == null || currentFamilyId == null) return;

    try {
      final repo = ref.read(groceryListRepositoryProvider);

      // Check for existing list
      final existingLists = await repo.getStandaloneListsForFamily(
        currentFamilyId,
      );
      final existingList = existingLists
          .where((l) => l.name == listName)
          .firstOrNull;

      late String listId;
      late bool isNew;

      if (existingList != null) {
        listId = existingList.id;
        isNew = false;
      } else {
        final list = await repo.createStandaloneList(
          familyId: currentFamilyId,
          name: listName,
          createdBy: currentUser.id,
        );
        listId = list.id;
        isNew = true;
      }

      // Add items
      await repo.addItemsBatch(listId: listId, items: items);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew
                  ? 'List "$listName" created!'
                  : 'Added items to "$listName"',
            ),
            action: SnackBarAction(
              label: 'View',
              onPressed: () {
                // Navigation to grocery list page would go here
                // for now just close snackbar
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save list: $e')));
      }
    }
  }

  Future<void> _generateSingleMeal() async {
    final type = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Which meal?'),
        children: ['Breakfast', 'Lunch', 'Dinner', 'Snack']
            .map(
              (t) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(t, style: const TextStyle(fontSize: 16)),
                ),
              ),
            )
            .toList(),
      ),
    );

    if (type == null) return;

    final currentUser = ref.read(currentUserProvider);
    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentUser == null || currentFamilyId == null) return;

    // 1. Get Preferences
    final currentPrefs =
        (currentUser.userMetadata?['dietary_preferences'] as List?)
            ?.cast<String>() ??
        [];
    final selectedTags = await _showPreferencesDialog(currentPrefs);
    if (selectedTags == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cooking up an idea...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final geminiService = ref.read(geminiServiceProvider);
      final hasKey = await geminiService.hasApiKey();

      if (!hasKey) {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          _showApiKeyDialog();
        }
        return;
      }

      final mealData = await geminiService.generateSingleMeal(
        mealType: type,
        dietaryTags: selectedTags,
      );

      final planRepo = ref.read(mealPlanRepositoryProvider);

      // Resolve Plan ID (same logic as day plan)
      String planId = '';
      MealPlanModel? plan;

      final currentPlan = ref
          .read(currentWeekMealPlanProvider(currentFamilyId))
          .value;
      if (currentPlan != null &&
          !_selectedDate.isBefore(currentPlan.startDate) &&
          !_selectedDate.isAfter(currentPlan.endDate)) {
        planId = currentPlan.id;
        plan = currentPlan;
      } else {
        plan = await planRepo.getOrCreateWeeklyPlan(
          currentFamilyId,
          _selectedDate,
        );
        planId = plan.id;
      }

      final existingEntry = plan.entries
          ?.cast<MealPlanEntryModel?>()
          .firstWhere(
            (e) =>
                DateUtils.isSameDay(e?.mealDate, _selectedDate) &&
                e?.mealType.toLowerCase() == type.toLowerCase(),
            orElse: () => null,
          );

      final entry = MealPlanEntryModel(
        id: existingEntry?.id ?? '',
        planId: planId,
        mealDate: _selectedDate,
        mealType: type.toLowerCase(),
        customNote: '${mealData['name']}: ${mealData['description']}',
        isCompleted: false,
        recipeId: null,
      );

      await planRepo.saveMealEntry(entry);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ref.invalidate(currentWeekMealPlanProvider(currentFamilyId));
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal updated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _saveGeneratedPlan(
    List<Map<String, dynamic>> generatedPlan,
  ) async {
    final familyId = ref.read(currentFamilyIdProvider);
    if (familyId == null) return;

    final planAsync = await ref.read(
      currentWeekMealPlanProvider(familyId).future,
    );
    final planId = planAsync.id;
    final startDate = planAsync.startDate;

    final existingEntries = planAsync.entries ?? [];

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      for (int i = 0; i < generatedPlan.length; i++) {
        final dayPlan = generatedPlan[i];
        final date = startDate.add(Duration(days: i));
        final meals = (dayPlan['meals'] as List).cast<Map<String, dynamic>>();

        for (final meal in meals) {
          final type = (meal['type'] as String).toLowerCase();

          // Find existing entry to update
          final existingEntry = existingEntries.where((e) {
            return DateUtils.isSameDay(e.mealDate, date) &&
                e.mealType.toLowerCase() == type;
          }).firstOrNull;

          final entry = MealPlanEntryModel(
            id:
                existingEntry?.id ??
                '', // Use existing ID to update, or empty to create
            planId: planId,
            mealDate: date,
            mealType: type,
            customNote: '${meal['name']}: ${meal['description']}',
            isCompleted: false,
            // Clear recipe link if we are overwriting with a generic AI plan
            recipeId: null,
          );

          await ref.read(mealPlanRepositoryProvider).saveMealEntry(entry);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ref.invalidate(currentWeekMealPlanProvider(familyId));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save plan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyId = ref.watch(currentFamilyIdProvider);
    final currentUser = ref.watch(currentUserProvider);
    final planAsync = ref.watch(
      currentWeekMealPlanProvider(currentFamilyId ?? ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Planner'),
        leading: IconButton(
          icon: Icon(
            Icons.menu_rounded,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_checkout),
            tooltip: 'Create Shopping List',
            onPressed: _handleAddToShoppingList,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Magic Plan',
            onPressed: _showMagicPlanOptions,
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
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
      body: planAsync.when(
        data: (plan) {
          // Normalize dates
          final today = DateTime.now();
          final startDate = plan.startDate;
          final days = List.generate(
            7,
            (index) => startDate.add(Duration(days: index)),
          );

          // Get entries for selected date
          final selectedDayEntries =
              plan.entries
                  ?.where((e) => DateUtils.isSameDay(e.mealDate, _selectedDate))
                  .toList() ??
              [];

          return Column(
            children: [
              // Month/Year Header
              Padding(
                padding: ResponsiveHelper.padding(
                  top: 16,
                  left: 16,
                  right: 16,
                  bottom: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      _getMonthRangeText(days.first, days.last),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.push(AppConstants.routeRecipes),
                      icon: Icon(
                        Icons.restaurant_menu,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        'My Recipes',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Date Strip
              _buildDateStrip(days, today),

              const Divider(height: 1),

              // Main Content
              Expanded(
                child: ListView(
                  padding: ResponsiveHelper.padding(all: 16),
                  children: [
                    _buildSectionHeader('Planned Meals'),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Breakfast',
                      Icons.wb_sunny_outlined,
                      Colors.orange,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Lunch',
                      Icons.restaurant,
                      Colors.green,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Dinner',
                      Icons.dinner_dining,
                      Colors.indigo,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                    SizedBox(height: 16.h),
                    _buildMealCard(
                      context,
                      'Snack',
                      Icons.local_cafe_outlined,
                      Colors.teal,
                      selectedDayEntries,
                      plan.id,
                      plan.familyId,
                      _selectedDate,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Error: $err'),
          ),
        ),
      ),
    );
  }

  String _getMonthRangeText(DateTime start, DateTime end) {
    if (start.month == end.month) {
      return DateFormat('MMMM yyyy').format(start);
    } else {
      // Spans two months
      final startFormat = DateFormat('MMM');
      final endFormat = DateFormat('MMM yyyy');
      if (start.year != end.year) {
        // Spans two years (rare but possible, e.g. Dec 29 - Jan 4)
        return '${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)}';
      }
      return '${startFormat.format(start)} - ${endFormat.format(end)}';
    }
  }

  Widget _buildDateStrip(List<DateTime> days, DateTime today) {
    return Container(
      height: 100.h,
      color: Theme.of(context).cardColor,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: ResponsiveHelper.padding(horizontal: 16, vertical: 16),
        itemCount: days.length,
        separatorBuilder: (context, index) => SizedBox(width: 12.w),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = DateUtils.isSameDay(day, _selectedDate);
          final isToday = DateUtils.isSameDay(day, today);

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = day),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : isToday
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(30.r), // Pill shape
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : isToday
                      ? AppTheme.primaryColor
                      : Colors.grey.withOpacity(0.2),
                  width: isToday && !isSelected ? 1.5 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(day).toUpperCase(),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('d').format(day),
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Future<void> _showRecipeDialog(
    String mealName,
    String? description,
    dynamic entry, // Pass the entry (is MealPlanEntryModel usually)
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final gemini = ref.read(geminiServiceProvider);
      // We can pass current dietary tags if we tracked them globally,
      // but for now let's just generate a standard recipe matching the description.
      // Improvement: Store dietary tags in the meal entry or pass from global state.
      final recipe = await gemini.generateRecipe(
        mealName: mealName,
        description: description,
      );

      // Check if already exists
      final familyId = ref.read(currentFamilyIdProvider);
      bool isAlreadySaved = false;
      if (familyId != null && recipe['title'] != null) {
        // We should really get the ID if it exists, not just bool
        // But repository method currently returns bool.
        // For now, if it exists, we assume user might want to create a NEW copy or link old?
        // The checkRecipeExists only returns bool.
        // Let's stick to the request: "If recipe already exists, disable import".
        // But if we want to LINK it, we'd need the ID.
        // For now, let's focus on the IMPORT flow (creating new).
        // If it exists, they can't import (button disabled), so they can't link via this flow?
        // Wait, if it exists, maybe we should finding it and linking it?
        // user said: "If the recipe already exists, then disable import".
        // So we assume duplicate recipes are bad.
        // But user ALSO said: "If a recipe is imported, switch from custom note to receipe directly".
        // Use case: I generate a recipe -> Save It -> My Meal Entry updates to link to it.
        isAlreadySaved = await ref
            .read(recipeRepositoryProvider)
            .checkRecipeExists(familyId, recipe['title']);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading

        await showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            // Use StatefulBuilder to update local loading state if needed
            builder: (context, setState) {
              return AlertDialog(
                title: Text(recipe['title'] ?? mealName),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (recipe['description'] != null) ...[
                          Text(
                            recipe['description'],
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // ... chips ...
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildInfoChip(Icons.timer, recipe['prepTime']),
                            _buildInfoChip(
                              Icons.soup_kitchen,
                              recipe['cookTime'],
                            ),
                            _buildInfoChip(
                              Icons.person,
                              '${recipe['servings']} servings',
                            ),
                          ],
                        ),
                        const Divider(),
                        const Text(
                          'Ingredients',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(recipe['ingredients'] as List? ?? []).map(
                          (i) => Text('• $i'),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Instructions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(recipe['instructions'] as List? ?? [])
                            .asMap()
                            .entries
                            .map((e) => Text('${e.key + 1}. ${e.value}\n')),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  FilledButton.icon(
                    onPressed: isAlreadySaved
                        ? null
                        : () async {
                            // Optimistic update
                            setState(() => isAlreadySaved = true);
                            await _saveRecipeToRepo(recipe, entry);
                          },
                    icon: Icon(isAlreadySaved ? Icons.check : Icons.save_alt),
                    label: Text(isAlreadySaved ? 'Saved' : 'Save to Recipes'),
                  ),
                ],
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate recipe: $e')),
        );
      }
    }
  }

  Future<void> _saveRecipeToRepo(
    Map<String, dynamic> recipeData,
    dynamic entry,
  ) async {
    // Show Loading to prevent double-tap and ensure correct context handling
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final familyId = ref.read(currentFamilyIdProvider);
      if (familyId == null) throw Exception('No family selected');

      // 1. Parse Integers (Regex to extract digits)
      int? parseTime(String? val) {
        if (val == null) return null;
        final match = RegExp(r'(\d+)').firstMatch(val);
        return match != null ? int.parse(match.group(1)!) : null;
      }

      final prepTime = parseTime(recipeData['prepTime']);
      final cookTime = parseTime(recipeData['cookTime']);
      final servings = parseTime(recipeData['servings'].toString()) ?? 4;

      // 2. Map Ingredients to Structured JSON
      // RecipeModel expects List<Map<String, dynamic>> usually {name, quantity, unit}
      // AI gives us a string list. We'll verify what RecipeModel expects.
      // Based on previous view, it expects List<Map<String, dynamic>>.
      // We will put the whole string in 'name' for simplicity as parsing NLP is hard.
      final ingredients = (recipeData['ingredients'] as List? ?? [])
          .map((i) => {'name': i.toString(), 'qty': 1, 'unit': ''})
          .toList()
          .cast<Map<String, dynamic>>();

      final instructions = (recipeData['instructions'] as List? ?? [])
          .map((i) => i.toString())
          .toList();

      // 3. Save
      final newRecipe = await ref
          .read(recipeRepositoryProvider)
          .createRecipe(
            familyId: familyId,
            title: recipeData['title'],
            description: recipeData['description'],
            prepTimeMinutes: prepTime,
            cookTimeMinutes: cookTime,
            servings: servings,
            ingredients: ingredients,
            instructions: instructions,
            tags: ['AI Generated'], // Tag it!
            sourceUrl: 'Magic Plan AI',
          );

      // LINK TO ENTRY if provided
      if (entry != null) {
        // Determine type of 'entry'. It should be MealPlanEntryModel.
        // Since we are inside the page file, we might not have the import visible or castable purely by dynamic.
        // We will assume it's the model object because we passed it.
        // We need to clone it with new recipeId.

        // Since 'dynamic', we rely on runtime reflection or just casting if we import the model.
        // Actually imports are at top of file. Let's check imports.
        // The file has access to `MealPlanEntryModel`.
        if (entry is MealPlanEntryModel) {
          final updatedEntry = entry.copyWith(
            recipeId: newRecipe.id,
            recipeTitle: newRecipe
                .title, // Ensure local display updates if stream is slow
            // customNote: null, // Maybe clear custom note? User said "switch from custom note to recipe"
            // Ideally we clear custom note if it was just the name.
          );
          await ref
              .read(mealPlanRepositoryProvider)
              .saveMealEntry(updatedEntry);
          ref.invalidate(currentWeekMealPlanProvider(familyId));
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close Loading
        Navigator.of(context, rootNavigator: true).pop(); // Close Recipe Dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recipe saved & linked!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close Loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }
  }

  Future<void> _regenerateSingleMeal(
    DateTime date,
    String mealType,
    String planId,
    String? currentEntryId,
  ) async {
    // 1. Get Preferences (Optional: reuse last or ask)
    // For speed, let's just ask quickly or use defaults.
    // Let's re-use the preference dialog but maybe simpler title?
    final tags = await _showPreferencesDialog(); // Reuse dialog
    if (tags == null) return;

    // 2. Show Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final gemini = ref.read(geminiServiceProvider);
      final meal = await gemini.generateSingleMeal(
        mealType: mealType,
        dietaryTags: tags,
      );

      final familyId = ref.read(currentFamilyIdProvider);
      if (familyId == null) throw Exception('No family selected');

      // 3. Update or Create Entry
      final entry = MealPlanEntryModel(
        id: currentEntryId ?? '', // Update if exists, else create
        planId: planId,
        mealDate: date,
        mealType: mealType.toLowerCase(),
        customNote: '${meal['name']}: ${meal['description']}',
        isCompleted: false,
        recipeId: null, // Clear recipe link on regen
      );

      await ref.read(mealPlanRepositoryProvider).saveMealEntry(entry);
      ref.invalidate(currentWeekMealPlanProvider(familyId));

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close Loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meal regenerated!')));
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close Loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to regenerate: $e')));
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String? label) {
    if (label == null) return const SizedBox();
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildMealCard(
    BuildContext context,
    String mealType,
    IconData icon,
    Color color,
    List<dynamic> entries,
    String planId,
    String familyId,
    DateTime date,
  ) {
    // Correctly cast and filter entries
    final entry = entries
        .map((e) => e as dynamic)
        .where((e) => e.mealType.toLowerCase() == mealType.toLowerCase())
        .firstOrNull;

    final isPlanned = entry != null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go(
              '${AppConstants.routeMealPlanner}/${AppConstants.routeMealSlotEdit}/$date/$mealType/$familyId/$planId',
              extra: entry,
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: ResponsiveHelper.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon/Image
                    Container(
                      width: 50.w,
                      height: 50.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(icon, color: color, size: 24.sp),
                    ),
                    SizedBox(width: 16.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealType,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            isPlanned
                                ? (entry.recipeTitle as String? ??
                                      entry.customNote as String? ??
                                      'Custom Meal')
                                : 'Not planned',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: isPlanned
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isPlanned
                                      ? null
                                      : Colors.grey.withOpacity(0.5),
                                  fontStyle: isPlanned
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                ),
                          ),
                          if (isPlanned && entry.recipeTitle != null) ...[
                            SizedBox(height: 4.h),
                            // Could add tags or time here if fetched
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 12.sp,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '30 min', // Placeholder or fetch from recipe
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Actions
                    IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 20),
                      tooltip: isPlanned ? 'Regenerate Meal' : 'Generate Meal',
                      onPressed: () => _regenerateSingleMeal(
                        date,
                        mealType,
                        planId,
                        entry?.id,
                      ),
                    ),

                    if (isPlanned)
                      IconButton(
                        icon: const Icon(Icons.menu_book),
                        tooltip: 'View Recipe',
                        onPressed: () {
                          _showRecipeDialog(
                            entry.recipeTitle as String? ??
                                entry.customNote as String? ??
                                'Meal',
                            entry.customNote as String?,
                            entry, // Pass the entry object for linking
                          );
                        },
                      ),

                    Icon(Icons.chevron_right, color: Colors.grey, size: 24.sp),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum ShoppingListScope { week, day }
