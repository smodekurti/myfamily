import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/role_permission_service.dart';
import '../models/meal_plan_model.dart';

class MealPlanRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

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
      print('Error fetching plan: $e');
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
    // Note: Joining recipe title in stream requires a view or client-side fetch.
    // For MVP, we'll store basic info or fetch recipes separately.
    // Actually, let's rely on fetching full plan on date change for now, and simple stream for status updates.
  }
}
