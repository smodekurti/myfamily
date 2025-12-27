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
import '../widgets/meal_planner_voting_dialog.dart';

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
    // Reset selected week to current week when entering page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(selectedWeekDateProvider.notifier).state = DateTime.now();
    });
  }

  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: AlertDialog(
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
    final result = await _showPreferencesDialog();
    if (result == null) return; // User cancelled

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
        dietaryTags: result.tags,
        cuisines: result.cuisines,
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

  Future<({List<String> tags, List<String> cuisines})?> _showPreferencesDialog([
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

    final List<String> cuisineOptions = [
      'Italian',
      'Mexican',
      'Indian',
      'Chinese',
      'American',
      'Mediterranean',
      'Thai',
      'Japanese',
      'French',
      'Greek',
    ];

    // Default selection
    List<String> selectedTags = List.from(initialSelection ?? []);
    List<String> selectedCuisines = [];

    return await showDialog<({List<String> tags, List<String> cuisines})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: AppTheme.globalTextScale),
            child: AlertDialog(
              title: const Text('Magic Plan Options'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select dietary requirements:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: options.map((option) {
                        final isSelected = selectedTags.contains(option);
                        return FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                selectedTags.add(option);
                              } else {
                                selectedTags.remove(option);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('Preferred Cuisines:'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cuisineOptions.map((option) {
                        final isSelected = selectedCuisines.contains(option);
                        return FilterChip(
                          label: Text(option),
                          selected: isSelected,
                          onSelected: (bool value) {
                            setState(() {
                              if (value) {
                                selectedCuisines.add(option);
                              } else {
                                selectedCuisines.remove(option);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, (
                    tags: selectedTags,
                    cuisines: selectedCuisines,
                  )),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPlanPreview(List<Map<String, dynamic>> generatedPlan) {
    showDialog(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: AlertDialog(
          title: const Text('Magic Plan Preview'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: generatedPlan.length,
              itemBuilder: (context, index) {
                final day = generatedPlan[index];
                final meals = (day['meals'] as List)
                    .cast<Map<String, dynamic>>();
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
      ),
    );
  }

  Future<void> _showMagicPlanOptions() async {
    final option = await showDialog<String>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: SimpleDialog(
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
            const Divider(),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'clear_week'),
              child: const ListTile(
                leading: Icon(Icons.delete_sweep, color: Colors.orange),
                title: Text('Clear Current Week'),
                subtitle: Text('Remove all meals for this week'),
              ),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'clear_day'),
              child: const ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.orange),
                title: Text('Clear Selected Day'),
                subtitle: Text('Remove meals for this day only'),
              ),
            ),
          ],
        ),
      ),
    );

    if (option == null) return;

    if (option == 'week') {
      await _generateFullWeekPlan();
    } else if (option == 'day') {
      await _generateDayPlan();
    } else if (option == 'meal') {
      await _generateSingleMeal();
    } else if (option == 'clear_week') {
      await _clearWeekPlan();
    } else if (option == 'clear_day') {
      await _clearDayPlan();
    }
  }

  Future<void> _clearWeekPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: AlertDialog(
          title: const Text('Clear Week?'),
          content: const Text(
            'This will remove all planned meals for the current week. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear All'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentFamilyId == null) return;

    final plan = ref.read(currentWeekMealPlanProvider(currentFamilyId)).value;
    if (plan == null) return;

    try {
      await ref.read(mealPlanRepositoryProvider).clearPlanEntries(plan.id);
      _refreshPlanData(currentFamilyId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Weekly plan cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear: $e')));
      }
    }
  }

  Future<void> _clearDayPlan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: AlertDialog(
          title: const Text('Clear Day?'),
          content: Text(
            'This will remove all meals planned for ${DateFormat('EEEE, MMM d').format(_selectedDate)}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Clear Day'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final currentFamilyId = ref.read(currentFamilyIdProvider);
    if (currentFamilyId == null) return;

    final plan = ref.read(currentWeekMealPlanProvider(currentFamilyId)).value;
    if (plan == null) return;

    try {
      await ref
          .read(mealPlanRepositoryProvider)
          .clearDayEntries(plan.id, _selectedDate);
      _refreshPlanData(currentFamilyId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Day plan cleared')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to clear: $e')));
      }
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
    final result = await _showPreferencesDialog(currentPrefs);
    if (result == null) return;

    // Check for existing entries and ask to clear
    final currentPlan = ref
        .read(currentWeekMealPlanProvider(currentFamilyId))
        .value;
    bool shouldClear = false;

    if (currentPlan != null && (currentPlan.entries?.isNotEmpty ?? false)) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: AppTheme.globalTextScale),
          child: AlertDialog(
            title: const Text('Existing Plan Found'),
            content: const Text(
              'You already have meals planned for this week. Do you want to clear them before generating a new plan, or add to them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'append'),
                child: const Text('Keep & Add'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'clear'),
                child: const Text('Clear & Generate'),
              ),
            ],
          ),
        ),
      );

      if (choice == 'cancel' || choice == null) return;
      shouldClear = choice == 'clear';
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: const Center(
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
        dietaryTags: result.tags,
        cuisines: result.cuisines,
      );

      // Save to database
      final planRepo = ref.read(mealPlanRepositoryProvider);

      // Use selected date as start, or now if selected is in past/today?
      // User request implies "from current day/time".
      // So regardless of _selectedDate navigation, "Magic Plan" usually means "Plan for me from NOW".
      // But if I navigated to next week, maybe I want to plan NEXT week.
      // Let's assume: If selected date is today or future, use selected. If selected is past, maybe defaulting to today is safer?
      // For now, let's respect _selectedDate as the "Anchor".
      // User said "from current day/time" explicitly. So let's align with "Today" if we are viewing "Today".
      // But if I am viewing next week, I probably want to plan next week.

      // Hybrid approach:
      // If _selectedDate is effectively today (same day), use Now.
      // If _selectedDate is future, use Start of that day.
      final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
      final startGenerationDate = isToday ? DateTime.now() : _selectedDate;
      // Normalize startGenerationDate to start of day for the loop calc, but keep time for filtering
      final startOfDay = DateTime(
        startGenerationDate.year,
        startGenerationDate.month,
        startGenerationDate.day,
      );

      // Clear if requested
      if (shouldClear) {
        // Smart clear: clear range from startGenerationDate to +7 days
        // We don't have a clearRange method yet, but we can iterate or add one.
        // For MVP, if they said "Clear", let's clear the overlap.
        // Actually, let's skip complex clear logic for now and rely on "Overwrite" behavior of save,
        // OR just clear the plan entries if we can find them.
        // Since we are moving to rolling, "Clear Week" concept is fuzzy.
        // Let's rely on the user's manual clear for now or simple overwrite.
        // Note: saveMealEntry updates if ID exists, or creates new. We don't have IDs for new gen.
        // So we should properly clear range if we want to avoid duplicates if we didn't match IDs.
        // But finding existing IDs to update is hard without fetching.
        // Let's fetch existing entries for the range first!
        final existing = await planRepo.getEntriesForDateRange(
          currentFamilyId,
          startOfDay,
          startOfDay.add(const Duration(days: 7)),
        );
        for (final e in existing) {
          await planRepo.deleteMealEntry(e.id);
        }
      }

      for (int i = 0; i < planData.length; i++) {
        final dayData = planData[i];
        final date = startOfDay.add(Duration(days: i));
        final meals = dayData['meals'] as List;

        for (final meal in meals) {
          final type = (meal['type'] as String).toLowerCase();

          // Smart Skip Logic:
          // If this is Day 0 (Today), and the meal type is "past", skip it.
          // Simple heuristic:
          // Breakfast < 11AM
          // Lunch < 3PM
          // Dinner < 9PM
          if (i == 0 && isToday) {
            final now = DateTime.now();
            if (type == 'breakfast' && now.hour >= 11) continue;
            if (type == 'lunch' && now.hour >= 15) continue;
            if (type == 'dinner' && now.hour >= 21)
              continue; // Unlikely but good safety
          }

          final entry = MealPlanEntryModel(
            id: '', // New entry
            planId: '', // Let repo resolve
            mealDate: date,
            mealType: type,
            customNote: '${meal['name']}: ${meal['description']}',
            isCompleted: false,
          );
          await planRepo.saveEntryForFamily(currentFamilyId, entry);
        }
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading
        _refreshPlanData(currentFamilyId);
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
    final result = await _showPreferencesDialog(currentPrefs);
    if (result == null) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: AppTheme.globalTextScale),
        child: const Center(
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
        dietaryTags: result.tags,
        cuisines: result.cuisines,
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

        await planRepo.saveEntryForFamily(currentFamilyId, entry);
      }

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _refreshPlanData(currentFamilyId);
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

      final result = await geminiService.extractIngredientsFromPlan(planData);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close loading

        final ingredientList = (result['ingredients'] as List)
            .cast<Map<String, dynamic>>();
        final estimatedCost = result['estimatedCost'] as String?;
        final staplesToCheck =
            (result['staplesToCheck'] as List?)?.cast<String>() ?? [];

        if (ingredientList.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ingredients could be extracted.')),
          );
          return;
        }

        // Show Smart Grocery Summary Dialog
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Smart Shopping List'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (estimatedCost != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_money, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Estimated Cost: $estimatedCost',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (staplesToCheck.isNotEmpty) ...[
                  const Text(
                    'Check your pantry for staples:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: staplesToCheck
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            backgroundColor: Colors.amber.withOpacity(0.2),
                            avatar: const Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: Colors.amber,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Ready to add ${ingredientList.length} items to your list?',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Create List'),
              ),
            ],
          ),
        );

        if (shouldProceed != true) return;

        // Ask where to add
        // Determine default list name
        final timestamp = DateTime.now();
        final listName =
            'Meal Plan Shopping (${timestamp.month}/${timestamp.day})';
        await _showAddToListDialog(
          ingredientList,
          listName,
        ); // Pass just the list as before
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

              // Robustly parse items
              final cleanItems = ingredients.map((item) {
                var qty = 1;
                if (item['qty'] is int) {
                  qty = item['qty'] as int;
                } else if (item['qty'] is double) {
                  qty = (item['qty'] as double).ceil();
                } else if (item['qty'] is String) {
                  final parsed = double.tryParse(item['qty']);
                  if (parsed != null) qty = parsed.ceil();
                }

                return {
                  'name': item['name'] ?? 'Unknown Item',
                  'category': item['category'] ?? 'Other',
                  'qty': qty,
                  'unit': item['unit'] ?? '',
                };
              }).toList();

              _addItemsToNewList(cleanItems, listName);
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
    final result = await _showPreferencesDialog(currentPrefs);
    if (result == null) return;

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
        dietaryTags: result.tags,
        cuisines: result.cuisines,
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

      await planRepo.saveEntryForFamily(currentFamilyId, entry);

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        _refreshPlanData(currentFamilyId);
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
        _refreshPlanData(familyId);
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

  void _refreshPlanData(String familyId) {
    ref.invalidate(currentWeekMealPlanProvider(familyId));
    final viewStartDate = ref.read(selectedWeekDateProvider);
    final startDate = DateTime(
      viewStartDate.year,
      viewStartDate.month,
      viewStartDate.day,
    );
    ref.invalidate(rollingMealPlanEntriesProvider((familyId, startDate)));
  }

  @override
  Widget build(BuildContext context) {
    final currentFamilyId = ref.watch(currentFamilyIdProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Decoupled logic:
    // View Window Start = selectedWeekDateProvider (Controlled by arrows)
    // Selected Date = _selectedDate (Controlled by tapping)

    // 1. Get the start of the Rolling Window
    final viewStartDate = ref.watch(selectedWeekDateProvider);
    // Normalize to start of day for the provider param
    final startDate = DateTime(
      viewStartDate.year,
      viewStartDate.month,
      viewStartDate.day,
    );

    // Watch the rolling entries using the view window start
    final entriesAsync = ref.watch(
      rollingMealPlanEntriesProvider((currentFamilyId ?? '', startDate)),
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
            onPressed: () => _handleAddToShoppingList(),
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
      body: entriesAsync.when(
        data: (entries) {
          // Normalize dates for display
          final today = DateTime.now();
          final days = List.generate(
            7,
            (index) => startDate.add(Duration(days: index)),
          );

          // Get entries for selected date for the details view
          // Filter entries where mealDate matches _selectedDate
          final selectedDayEntries = entries
              .where((e) => DateUtils.isSameDay(e.mealDate, _selectedDate))
              .toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                currentWeekMealPlanProvider(currentFamilyId ?? ''),
              );
              ref.invalidate(
                rollingMealPlanEntriesProvider((
                  currentFamilyId ?? '',
                  startDate,
                )),
              );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
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
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              final current = ref.read(
                                selectedWeekDateProvider,
                              );
                              final newDate = current.subtract(
                                const Duration(days: 7),
                              );
                              ref
                                      .read(selectedWeekDateProvider.notifier)
                                      .state =
                                  newDate;
                              setState(() {
                                _selectedDate = newDate;
                              });
                            },
                          ),
                          Text(
                            _getMonthRangeText(days.first, days.last),
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              final current = ref.read(
                                selectedWeekDateProvider,
                              );
                              final newDate = current.add(
                                const Duration(days: 7),
                              );
                              ref
                                      .read(selectedWeekDateProvider.notifier)
                                      .state =
                                  newDate;
                              setState(() {
                                _selectedDate = newDate;
                              });
                            },
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                context.push(AppConstants.routeRecipes),
                            icon: Icon(
                              Icons.restaurant_menu,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            tooltip: 'My Recipes',
                          ),
                        ],
                      ),
                    ),

                    // Horizontal Date Strip
                    _buildDateStrip(days, today),

                    const Divider(height: 1),

                    // Main Content
                    // Main Content
                    Padding(
                      padding: ResponsiveHelper.padding(all: 16),
                      child: Column(
                        children: [
                          _buildSectionHeader('Planned Meals'),
                          SizedBox(height: 16.h),
                          _buildMealCard(
                            context,
                            'Breakfast',
                            Icons.wb_sunny_outlined,
                            Colors.orange,
                            selectedDayEntries,
                            '', // Resolved by date/entry
                            currentFamilyId ?? '',
                            _selectedDate,
                          ),
                          SizedBox(height: 16.h),
                          _buildMealCard(
                            context,
                            'Lunch',
                            Icons.restaurant,
                            Colors.green,
                            selectedDayEntries,
                            '',
                            currentFamilyId ?? '',
                            _selectedDate,
                          ),
                          SizedBox(height: 16.h),
                          _buildMealCard(
                            context,
                            'Dinner',
                            Icons.dinner_dining,
                            Colors.indigo,
                            selectedDayEntries,
                            '',
                            currentFamilyId ?? '',
                            _selectedDate,
                          ),
                          SizedBox(height: 16.h),
                          _buildMealCard(
                            context,
                            'Snack',
                            Icons.local_cafe_outlined,
                            Colors.teal,
                            selectedDayEntries,
                            '',
                            currentFamilyId ?? '',
                            _selectedDate,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
    final prefs = await _showPreferencesDialog(); // Reuse dialog
    if (prefs == null) return;

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
        dietaryTags: prefs.tags,
        cuisines: prefs.cuisines,
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

      // Save with smart plan resolution
      await ref
          .read(mealPlanRepositoryProvider)
          .saveEntryForFamily(familyId, entry);

      // Invalidate the rolling view. We assume the view is based on the selected date.
      final selectedDate = ref.read(selectedWeekDateProvider);
      // Normalize to start of day as done in build
      final startDate = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      ref.invalidate(rollingMealPlanEntriesProvider((familyId, startDate)));

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
            context.pushNamed(
              'edit-meal-slot',
              pathParameters: {
                'date': date.toString(),
                'mealType': mealType,
                'familyId': familyId,
                'planId': planId.isEmpty ? 'auto' : planId,
              },
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
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(icon, color: color, size: 20.sp),
                    ),
                    SizedBox(width: 12.w),

                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mealType,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            isPlanned
                                ? (entry.recipeTitle as String? ??
                                      entry.customNote as String? ??
                                      'Custom Meal')
                                : 'Not planned',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: isPlanned
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isPlanned
                                      ? null
                                      : Colors.grey.withOpacity(0.5),
                                  fontStyle: isPlanned
                                      ? FontStyle.normal
                                      : FontStyle.italic,
                                  height: 1.2,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isPlanned && entry.recipeTitle != null) ...[
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 10.sp,
                                  color: Colors.grey,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '30 min', // Placeholder
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.grey,
                                        fontSize: 10.sp,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Action Menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: Colors.grey,
                        size: 20.sp,
                      ),
                      onSelected: (value) {
                        if (value == 'vote') {
                          // Use saved preferences directly for seamless experience
                          final currentUser = ref.read(currentUserProvider);
                          final dietaryTags =
                              (currentUser?.userMetadata?['dietary_preferences']
                                      as List?)
                                  ?.cast<String>() ??
                              [];

                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => MealPlannerVotingDialog(
                                mealType: mealType,
                                date: date,
                                dietaryTags: dietaryTags,
                                cuisines: const [],
                                onSessionCreated: (session) {
                                  // TODO: Save session
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Voting started!'),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        } else if (value == 'generate') {
                          _regenerateSingleMeal(
                            date,
                            mealType,
                            planId,
                            entry?.id,
                          );
                        } else if (value == 'view') {
                          _showRecipeDialog(
                            entry.recipeTitle as String? ??
                                entry.customNote as String? ??
                                'Meal',
                            entry.customNote as String?,
                            entry,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'vote',
                          child: Row(
                            children: const [
                              Icon(Icons.how_to_vote_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Start Vote'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'generate',
                          child: Row(
                            children: [
                              Icon(
                                isPlanned ? Icons.refresh : Icons.auto_awesome,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(isPlanned ? 'Regenerate' : 'Generate'),
                            ],
                          ),
                        ),
                        if (isPlanned)
                          PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: const [
                                Icon(Icons.menu_book_outlined, size: 20),
                                SizedBox(width: 8),
                                Text('View Recipe'),
                              ],
                            ),
                          ),
                      ],
                    ),
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
