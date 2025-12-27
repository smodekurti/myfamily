import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/role_permission_service.dart';
import '../models/meal_plan_model.dart';

class MealPlanRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Logger _logger = Logger();

  /// Get or create a meal plan for a specific week (start date)
  Future<MealPlanModel> getOrCreateWeeklyPlan(
    String familyId,
    DateTime startDate,
  ) async {
    // Ensure start date is normalized to start of day, or handled consistently
    final dateStr = startDate.toIso8601String().split('T').first;

    // Try to find existing plan
    try {
      final response = await _supabase
          .from('meal_plans')
          .select(
            '*, entries:meal_plan_entries(*, recipes:recipes(title, image_url))',
          )
          .eq('family_id', familyId)
          .eq('start_date', dateStr)
          .maybeSingle();

      if (response != null) {
        // Map entries manually because of the join
        final planData = Map<String, dynamic>.from(response);
        final entriesData = (planData['entries'] as List<dynamic>?) ?? [];
        final entries = entriesData
            .map((e) => MealPlanEntryModelHelpers.fromSupabase(e))
            .toList();

        // Remove entries from top level before parsing plan model to avoid type errors if not handled
        planData.remove('entries');

        return MealPlanModelHelpers.fromSupabase(
          planData,
        ).copyWith(entries: entries);
      }
    } catch (e) {
      // Ignore and create
      _logger.e('Error fetching plan: $e');
    }

    // Create new plan
    final endDate = startDate.add(const Duration(days: 6));

    final newPlan = MealPlanModel(
      id: '',
      familyId: familyId,
      startDate: startDate,
      endDate: endDate,
    );

    final response = await _supabase
        .from('meal_plans')
        .insert(MealPlanModelHelpers.toSupabase(newPlan))
        .select()
        .single();

    return MealPlanModelHelpers.fromSupabase(response).copyWith(entries: []);
  }

  /// Add or Update a meal entry
  Future<MealPlanEntryModel> saveMealEntry(MealPlanEntryModel entry) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not logged in');

    if (entry.id.isEmpty) {
      // Create
      final response = await _supabase
          .from('meal_plan_entries')
          .insert(MealPlanEntryModelHelpers.toSupabase(entry))
          .select()
          .single();
      return MealPlanEntryModelHelpers.fromSupabase(response);
    } else {
      // Update
      final response = await _supabase
          .from('meal_plan_entries')
          .update(MealPlanEntryModelHelpers.toSupabase(entry))
          .eq('id', entry.id)
          .select()
          .single();
      return MealPlanEntryModelHelpers.fromSupabase(response);
    }
  }

  /// Delete a meal entry
  Future<void> deleteMealEntry(String entryId) async {
    await _supabase.from('meal_plan_entries').delete().eq('id', entryId);
  }

  /// Delete all entries for a plan (Clear Week)
  Future<void> clearPlanEntries(String planId) async {
    await _supabase.from('meal_plan_entries').delete().eq('plan_id', planId);
  }

  /// Delete entries for a specific day (Clear Day)
  Future<void> clearDayEntries(String planId, DateTime date) async {
    // Standardize date to ensure matches (assuming stored as date string or timestamp at midnight)
    // The model uses DateTime, but likely stored as timestamptz or date in Supabase.
    // If it's a full timestamp, we need a range or ensure exact match.
    // Looking at meal_plan_model, mealDate is DateTime.
    // Let's assume we want to match the day.
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Supabase date filtering
    await _supabase
        .from('meal_plan_entries')
        .delete()
        .eq('plan_id', planId)
        .gte('meal_date', startOfDay.toIso8601String())
        .lt('meal_date', endOfDay.toIso8601String());
  }

  /// Stream current week's plan (Not trivial with join, might need simpler stream or just fetch)
  /// For simplicity in MVP, we might reload on focus or use a separate stream for entries.
  /// Here is a stream of ENTRIES for a given plan ID
  Stream<List<MealPlanEntryModel>> streamPlanEntries(String planId) {
    return _supabase
        .from('meal_plan_entries')
        .stream(primaryKey: ['id'])
        .eq('plan_id', planId)
        .order('meal_date')
        .map(
          (data) => data
              .map((json) => MealPlanEntryModelHelpers.fromSupabase(json))
              .toList(),
        );
  }

  /// Get entries for a specific date range across any plans
  /// Useful for rolling views (e.g. Next 7 Days irrespective of calendar week)
  Future<List<MealPlanEntryModel>> getEntriesForDateRange(
    String familyId,
    DateTime start,
    DateTime end,
  ) async {
    // 1. Get plan IDs that overlap with range (optional optimization, or just query entries joined with plans)
    // Supabase join syntax: meal_plan_entries!inner(..., meal_plans!inner(family_id))
    // Simpler: Fetch all plans for family in range, then fetch entries.
    // Or just query entries and filter by plan_id in the list of family plans.

    // Let's use the join approach if possible, or two steps.
    // Step 1: Get entries where meal_date is in range.
    // Step 2: Filter by family_id (join meal_plans).
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    try {
      final response = await _supabase
          .from('meal_plan_entries')
          .select('*, meal_plans!inner(family_id)')
          .eq('meal_plans.family_id', familyId)
          .gte('meal_date', startStr)
          .lte('meal_date', endStr)
          .order('meal_date');

      return (response as List)
          .map((e) => MealPlanEntryModelHelpers.fromSupabase(e))
          .toList();
    } catch (e) {
      _logger.e('Error fetching range entries: $e');
      return [];
    }
  }

  /// Save an entry, automatically resolving the correct weekly plan ID
  Future<MealPlanEntryModel> saveEntryForFamily(
    String familyId,
    MealPlanEntryModel entry,
  ) async {
    // If planId is missing, resolve it based on date
    String planId = entry.planId;
    if (planId.isEmpty) {
      // Calculate start of week (Sunday) for the entry's date
      final date = entry.mealDate;
      final daysToSubtract = date.weekday % 7;
      final startOfWeek = date.subtract(Duration(days: daysToSubtract));
      final normalizedStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final plan = await getOrCreateWeeklyPlan(familyId, normalizedStart);
      planId = plan.id;
    }

    // Save with resolved ID
    return saveMealEntry(entry.copyWith(planId: planId));
  }
}
