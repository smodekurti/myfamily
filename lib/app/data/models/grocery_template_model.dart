import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery_template_model.freezed.dart';
part 'grocery_template_model.g.dart';

/// Grocery template - reusable grocery list templates
@freezed
class GroceryTemplateModel with _$GroceryTemplateModel {
  const factory GroceryTemplateModel({
    required String id,
    required String familyId,
    required String name,
    String? icon,
    String? color,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryTemplateModel;

  factory GroceryTemplateModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryTemplateModelFromJson(json);
}

/// Grocery template item - items within a template
@freezed
class GroceryTemplateItemModel with _$GroceryTemplateItemModel {
  const factory GroceryTemplateItemModel({
    required String id,
    required String templateId,
    required String name,
    required String category, // 'produce', 'dairy', etc.
    @Default(1) int defaultQty,
    String? notes,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryTemplateItemModel;

  factory GroceryTemplateItemModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryTemplateItemModelFromJson(json);
}

/// Grocery list - can be standalone or attached to a task
@freezed
class GroceryListModel with _$GroceryListModel {
  const factory GroceryListModel({
    required String id,
    String? taskId, // Optional: Links to a task if this list is part of a task. NULL for standalone lists.
    required String familyId,
    required String name,
    String? templateId, // If created from template
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryListModel;

  factory GroceryListModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryListModelFromJson(json);
}

/// Grocery list item - items in a grocery list attached to a task
@freezed
class GroceryListItemModel with _$GroceryListItemModel {
  const GroceryListItemModel._();
  
  const factory GroceryListItemModel({
    required String id,
    required String listId,
    required String name,
    required String category,
    @Default(1) int qty,
    String? notes,
    String? unit,
    @Default(false) bool checked,
    DateTime? checkedAt,
    String? source, // 'template' or 'manual'
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryListItemModel;

  factory GroceryListItemModel.fromJson(Map<String, dynamic> json) =>
      _$GroceryListItemModelFromJson(json);
  
  GroceryListItemModel toggleCheck() {
    final bool newChecked = !this.checked;
    return copyWith(
      checked: newChecked,
      checkedAt: newChecked ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }
}

// Helper extensions
extension GroceryItemCategoryExtension on String {
  String get displayName {
    switch (toLowerCase()) {
      case 'produce':
        return 'Produce';
      case 'dairy':
      case 'dairy & eggs':
        return 'Dairy & Eggs';
      case 'meat':
        return 'Meat';
      case 'bakery':
        return 'Bakery';
      case 'frozen':
        return 'Frozen';
      case 'pantry':
        return 'Pantry';
      case 'beverages':
        return 'Beverages';
      case 'household':
        return 'Household';
      case 'health':
        return 'Health';
      default:
        return 'Other';
    }
  }
}

