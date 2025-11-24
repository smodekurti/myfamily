// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroceryMasterModelImpl _$$GroceryMasterModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryMasterModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  store: json['store'] as String?,
  description: json['description'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryMasterModelImplToJson(
  _$GroceryMasterModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'name': instance.name,
  'store': instance.store,
  'description': instance.description,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$GroceryMasterItemModelImpl _$$GroceryMasterItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryMasterItemModelImpl(
  id: json['id'] as String,
  masterId: json['masterId'] as String,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  category: $enumDecode(_$GroceryItemCategoryEnumMap, json['category']),
  defaultQty: (json['defaultQty'] as num?)?.toInt() ?? 1,
  notes: json['notes'] as String?,
  unit: json['unit'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryMasterItemModelImplToJson(
  _$GroceryMasterItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'masterId': instance.masterId,
  'familyId': instance.familyId,
  'name': instance.name,
  'category': _$GroceryItemCategoryEnumMap[instance.category]!,
  'defaultQty': instance.defaultQty,
  'notes': instance.notes,
  'unit': instance.unit,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$GroceryItemCategoryEnumMap = {
  GroceryItemCategory.produce: 'produce',
  GroceryItemCategory.meat: 'meat',
  GroceryItemCategory.dairy: 'dairy',
  GroceryItemCategory.bakery: 'bakery',
  GroceryItemCategory.frozen: 'frozen',
  GroceryItemCategory.pantry: 'pantry',
  GroceryItemCategory.beverages: 'beverages',
  GroceryItemCategory.household: 'household',
  GroceryItemCategory.health: 'health',
  GroceryItemCategory.other: 'other',
};

_$GroceryTripModelImpl _$$GroceryTripModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryTripModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  masterId: json['masterId'] as String?,
  assignee: json['assignee'] as String,
  store: json['store'] as String?,
  status:
      $enumDecodeNullable(_$GroceryTripStatusEnumMap, json['status']) ??
      GroceryTripStatus.pending,
  startedAt: json['startedAt'] == null
      ? null
      : DateTime.parse(json['startedAt'] as String),
  completedAt: json['completedAt'] == null
      ? null
      : DateTime.parse(json['completedAt'] as String),
  createdBy: json['createdBy'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryTripModelImplToJson(
  _$GroceryTripModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'masterId': instance.masterId,
  'assignee': instance.assignee,
  'store': instance.store,
  'status': _$GroceryTripStatusEnumMap[instance.status]!,
  'startedAt': instance.startedAt?.toIso8601String(),
  'completedAt': instance.completedAt?.toIso8601String(),
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

const _$GroceryTripStatusEnumMap = {
  GroceryTripStatus.pending: 'pending',
  GroceryTripStatus.inProgress: 'in_progress',
  GroceryTripStatus.completed: 'completed',
  GroceryTripStatus.cancelled: 'cancelled',
};

_$GroceryTripItemModelImpl _$$GroceryTripItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryTripItemModelImpl(
  id: json['id'] as String,
  tripId: json['tripId'] as String,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  category: $enumDecode(_$GroceryItemCategoryEnumMap, json['category']),
  qty: (json['qty'] as num?)?.toInt() ?? 1,
  notes: json['notes'] as String?,
  unit: json['unit'] as String?,
  checked: json['checked'] as bool? ?? false,
  checkedAt: json['checkedAt'] == null
      ? null
      : DateTime.parse(json['checkedAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryTripItemModelImplToJson(
  _$GroceryTripItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'tripId': instance.tripId,
  'familyId': instance.familyId,
  'name': instance.name,
  'category': _$GroceryItemCategoryEnumMap[instance.category]!,
  'qty': instance.qty,
  'notes': instance.notes,
  'unit': instance.unit,
  'checked': instance.checked,
  'checkedAt': instance.checkedAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
