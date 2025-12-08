import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
class RecipeModel with _$RecipeModel {
  const factory RecipeModel({
    required String id,
    required String familyId,
    required String title,
    String? description,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    @Default(4) int servings,
    List<Map<String, dynamic>>? ingredients, // List of {name, quantity, unit}
    List<String>? instructions,
    List<String>? tags,
    String? imageUrl,
    String? sourceUrl,
    String? createdBy,
    DateTime? createdAt,
  }) = _RecipeModel;

  factory RecipeModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeModelFromJson(json);
}

class RecipeModelHelpers {
  static RecipeModel fromSupabase(Map<String, dynamic> data) {
    // Map snake_case DB columns to camelCase Dart fields
    final Map<String, dynamic> json = Map.from(data);

    // Explicit mappings
    if (data.containsKey('prep_time_minutes')) {
      json['prepTimeMinutes'] = data['prep_time_minutes'];
    }
    if (data.containsKey('cook_time_minutes')) {
      json['cookTimeMinutes'] = data['cook_time_minutes'];
    }
    if (data.containsKey('image_url')) {
      json['imageUrl'] = data['image_url'];
    }
    if (data.containsKey('source_url')) {
      json['sourceUrl'] = data['source_url'];
    }
    if (data.containsKey('family_id')) {
      json['familyId'] = data['family_id'];
    }
    if (data.containsKey('created_at')) {
      json['createdAt'] = data['created_at'];
    }
    if (data.containsKey('created_by')) {
      json['createdBy'] = data['created_by'];
    }

    return RecipeModel.fromJson(json);
  }

  static Map<String, dynamic> toSupabase(RecipeModel recipe) {
    final Map<String, dynamic> data = {
      'family_id': recipe.familyId,
      'title': recipe.title,
      'servings': recipe.servings,
    };

    // Optional fields
    if (recipe.id.isNotEmpty) {
      data['id'] = recipe.id;
    }
    if (recipe.description != null) {
      data['description'] = recipe.description;
    }
    if (recipe.prepTimeMinutes != null) {
      data['prep_time_minutes'] = recipe.prepTimeMinutes;
    }
    if (recipe.cookTimeMinutes != null) {
      data['cook_time_minutes'] = recipe.cookTimeMinutes;
    }
    if (recipe.ingredients != null) {
      data['ingredients'] = recipe.ingredients;
    }
    if (recipe.instructions != null) {
      data['instructions'] = recipe.instructions;
    }
    if (recipe.tags != null) {
      data['tags'] = recipe.tags;
    }
    if (recipe.imageUrl != null) {
      data['image_url'] = recipe.imageUrl;
    }
    if (recipe.sourceUrl != null) {
      data['source_url'] = recipe.sourceUrl;
    }
    if (recipe.createdBy != null) {
      data['created_by'] = recipe.createdBy;
    }
    if (recipe.createdAt != null) {
      data['created_at'] = recipe.createdAt!.toIso8601String();
    }

    return data;
  }
}
