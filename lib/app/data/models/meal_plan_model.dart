import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_plan_model.freezed.dart';
part 'meal_plan_model.g.dart';

@freezed
class MealPlanModel with _$MealPlanModel {
  const factory MealPlanModel({
    required String id,
    required String familyId,
    required DateTime startDate,
    required DateTime endDate,
    DateTime? createdAt,
    // Optional list of entries, populated when fetching full plan
    List<MealPlanEntryModel>? entries,
  }) = _MealPlanModel;

  factory MealPlanModel.fromJson(Map<String, dynamic> json) =>
      _$MealPlanModelFromJson(json);
}

@freezed
class MealPlanEntryModel with _$MealPlanEntryModel {
  const factory MealPlanEntryModel({
    required String id,
    required String planId,
    String? recipeId,
    required DateTime mealDate,
    required String mealType, // 'breakfast', 'lunch', 'dinner', 'snack'
    String? customNote,
    @Default(false) bool isCompleted,
    DateTime? createdAt,
    // Optional joined fields
    String? recipeTitle,
    String? recipeImageUrl,
  }) = _MealPlanEntryModel;

  factory MealPlanEntryModel.fromJson(Map<String, dynamic> json) =>
      _$MealPlanEntryModelFromJson(json);
}

class MealPlanModelHelpers {
  static MealPlanModel fromSupabase(Map<String, dynamic> data) {
    return MealPlanModel(
      id: data['id'] as String,
      familyId: data['family_id'] as String,
      startDate: DateTime.parse(data['start_date'] as String),
      endDate: DateTime.parse(data['end_date'] as String),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      entries:
          null, // Entries are typically populated separately or need similar manual mapping if passed here
    );
  }

  static Map<String, dynamic> toSupabase(MealPlanModel plan) {
    final Map<String, dynamic> data = {
      'family_id': plan.familyId,
      'start_date': plan.startDate.toIso8601String(),
      'end_date': plan.endDate.toIso8601String(),
    };

    if (plan.id.isNotEmpty) {
      data['id'] = plan.id;
    }
    if (plan.createdAt != null) {
      data['created_at'] = plan.createdAt!.toIso8601String();
    }

    return data;
  }
}

class MealPlanEntryModelHelpers {
  static MealPlanEntryModel fromSupabase(Map<String, dynamic> data) {
    // Handle joined fields if present
    final json = Map<String, dynamic>.from(data);

    // Map snake_case from DB to camelCase for Model
    // We need to check if 'plan_id' exists and map it to 'planId', etc.
    // However, Freezed usually uses @JsonKey to handle this if we annotated it.
    // Since we are using manual helpers, we should ensure the input to fromJson is correct.
    // BUT: fromJson expect camelCase keys matching the factory constructor if we didn't annotate.
    // Let's rely on the current fromJson behavior which implies we might need to map DB keys -> Model keys.
    // Wait, typically we use @JsonSerializable(fieldRename: FieldRename.snake) or @JsonKey(name: 'snake_case').
    // If we haven't done that (and we haven't in the viewed file), then `fromJson` expects camelCase.
    // The previous implementation just called `fromJson(data)`, which heavily suggests `data` from Supabase (snake_case)
    // was being passed to `fromJson` (expecting camelCase) and failing silently or partially work if names match.
    // `startDate` vs `start_date`. Check the viewed file again.

    // Ah, line 18: `factory MealPlanModel.fromJson(Map<String, dynamic> json) => _$MealPlanModelFromJson(json);`
    // If no annotations, it expects `startDate`, `familyId`.
    // The DB returns `start_date`, `family_id`.
    // So the READ path (`fromSupabase`) is ALSO questionable unless `freezed` generated code is handling it (unlikely without annotation).
    // I should fix BOTH `fromSupabase` (snake -> camel) and `toSupabase` (camel -> snake),
    // OR easier: annotate the models with `@JsonKey(name: 'snake_case')` if possible, but I can't edit generated code easily.
    // I will rewrite the helpers to do explicit mapping.

    if (data['recipes'] != null) {
      final recipe = data['recipes'] as Map<String, dynamic>;
      json['recipeTitle'] = recipe['title'];
      json['recipeImageUrl'] = recipe['image_url'];
    }

    // Manually map DB keys to Model keys for fromJson
    // This is safer than editing the model file deeply and regenerating.
    return MealPlanEntryModel(
      id: data['id'] as String,
      planId: data['plan_id'] as String,
      recipeId: data['recipe_id'] as String?,
      mealDate: DateTime.parse(data['meal_date'] as String),
      mealType: data['meal_type'] as String,
      customNote: data['custom_note'] as String?,
      isCompleted: data['is_completed'] as bool? ?? false,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      recipeTitle: json['recipeTitle'] as String?,
      recipeImageUrl: json['recipeImageUrl'] as String?,
    );
  }

  static Map<String, dynamic> toSupabase(MealPlanEntryModel entry) {
    final Map<String, dynamic> data = {
      'plan_id': entry.planId,
      'meal_date': entry.mealDate.toIso8601String(),
      'meal_type': entry.mealType,
      'is_completed': entry.isCompleted,
    };

    if (entry.id.isNotEmpty) {
      data['id'] = entry.id;
    }
    if (entry.recipeId != null) {
      data['recipe_id'] = entry.recipeId;
    }
    if (entry.customNote != null) {
      data['custom_note'] = entry.customNote;
    }
    if (entry.createdAt != null) {
      data['created_at'] = entry.createdAt!.toIso8601String();
    }

    return data;
  }
}
