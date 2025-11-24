import 'package:freezed_annotation/freezed_annotation.dart';

part 'grocery_model.freezed.dart';
part 'grocery_model.g.dart';

enum GroceryTripStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
}

enum GroceryItemCategory {
  @JsonValue('produce')
  produce,
  @JsonValue('meat')
  meat,
  @JsonValue('dairy')
  dairy,
  @JsonValue('bakery')
  bakery,
  @JsonValue('frozen')
  frozen,
  @JsonValue('pantry')
  pantry,
  @JsonValue('beverages')
  beverages,
  @JsonValue('household')
  household,
  @JsonValue('health')
  health,
  @JsonValue('other')
  other,
}

@freezed
class GroceryMasterModel with _$GroceryMasterModel {
  const factory GroceryMasterModel({
    required String id,
    required String familyId,
    required String name,
    String? store,
    String? description,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryMasterModel;

  factory GroceryMasterModel.fromJson(Map<String, dynamic> json) => _$GroceryMasterModelFromJson(json);
}

@freezed
class GroceryMasterItemModel with _$GroceryMasterItemModel {
  const factory GroceryMasterItemModel({
    required String id,
    required String masterId,
    required String familyId,
    required String name,
    required GroceryItemCategory category,
    @Default(1) int defaultQty,
    String? notes,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryMasterItemModel;

  factory GroceryMasterItemModel.fromJson(Map<String, dynamic> json) => _$GroceryMasterItemModelFromJson(json);
}

@freezed
class GroceryTripModel with _$GroceryTripModel {
  const factory GroceryTripModel({
    required String id,
    required String familyId,
    String? masterId,
    required String assignee,
    String? store,
    @Default(GroceryTripStatus.pending) GroceryTripStatus status,
    DateTime? startedAt,
    DateTime? completedAt,
    required String createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryTripModel;

  factory GroceryTripModel.fromJson(Map<String, dynamic> json) => _$GroceryTripModelFromJson(json);
}

@freezed
class GroceryTripItemModel with _$GroceryTripItemModel {
  const GroceryTripItemModel._();
  
  const factory GroceryTripItemModel({
    required String id,
    required String tripId,
    required String familyId,
    required String name,
    required GroceryItemCategory category,
    @Default(1) int qty,
    String? notes,
    String? unit,
    @Default(false) bool checked,
    DateTime? checkedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _GroceryTripItemModel;

  factory GroceryTripItemModel.fromJson(Map<String, dynamic> json) => _$GroceryTripItemModelFromJson(json);
  
  GroceryTripItemModel toggleCheck() {
    return copyWith(
      checked: !this.checked,
      checkedAt: !this.checked ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );
  }
}

// Extension methods
extension GroceryTripModelExtension on GroceryTripModel {
  bool get isActive => status == GroceryTripStatus.inProgress;
  bool get isCompleted => status == GroceryTripStatus.completed;
  bool get isPending => status == GroceryTripStatus.pending;
}

// Helper extensions for display
extension GroceryItemCategoryExtension on GroceryItemCategory {
  String get displayName {
    switch (this) {
      case GroceryItemCategory.produce:
        return 'Produce';
      case GroceryItemCategory.meat:
        return 'Meat';
      case GroceryItemCategory.dairy:
        return 'Dairy';
      case GroceryItemCategory.bakery:
        return 'Bakery';
      case GroceryItemCategory.frozen:
        return 'Frozen';
      case GroceryItemCategory.pantry:
        return 'Pantry';
      case GroceryItemCategory.beverages:
        return 'Beverages';
      case GroceryItemCategory.household:
        return 'Household';
      case GroceryItemCategory.health:
        return 'Health';
      case GroceryItemCategory.other:
        return 'Other';
    }
  }
}

extension GroceryTripStatusExtension on GroceryTripStatus {
  String get displayName {
    switch (this) {
      case GroceryTripStatus.pending:
        return 'Pending';
      case GroceryTripStatus.inProgress:
        return 'In Progress';
      case GroceryTripStatus.completed:
        return 'Completed';
      case GroceryTripStatus.cancelled:
        return 'Cancelled';
    }
  }
}
