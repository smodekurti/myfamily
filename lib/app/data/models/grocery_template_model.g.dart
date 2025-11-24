// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_template_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroceryTemplateModelImpl _$$GroceryTemplateModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryTemplateModelImpl(
  id: json['id'] as String,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  icon: json['icon'] as String?,
  color: json['color'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryTemplateModelImplToJson(
  _$GroceryTemplateModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'familyId': instance.familyId,
  'name': instance.name,
  'icon': instance.icon,
  'color': instance.color,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$GroceryTemplateItemModelImpl _$$GroceryTemplateItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryTemplateItemModelImpl(
  id: json['id'] as String,
  templateId: json['templateId'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
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

Map<String, dynamic> _$$GroceryTemplateItemModelImplToJson(
  _$GroceryTemplateItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'templateId': instance.templateId,
  'name': instance.name,
  'category': instance.category,
  'defaultQty': instance.defaultQty,
  'notes': instance.notes,
  'unit': instance.unit,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$GroceryListModelImpl _$$GroceryListModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryListModelImpl(
  id: json['id'] as String,
  taskId: json['taskId'] as String?,
  familyId: json['familyId'] as String,
  name: json['name'] as String,
  templateId: json['templateId'] as String?,
  createdBy: json['createdBy'] as String,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryListModelImplToJson(
  _$GroceryListModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'taskId': instance.taskId,
  'familyId': instance.familyId,
  'name': instance.name,
  'templateId': instance.templateId,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

_$GroceryListItemModelImpl _$$GroceryListItemModelImplFromJson(
  Map<String, dynamic> json,
) => _$GroceryListItemModelImpl(
  id: json['id'] as String,
  listId: json['listId'] as String,
  name: json['name'] as String,
  category: json['category'] as String,
  qty: (json['qty'] as num?)?.toInt() ?? 1,
  notes: json['notes'] as String?,
  unit: json['unit'] as String?,
  checked: json['checked'] as bool? ?? false,
  checkedAt: json['checkedAt'] == null
      ? null
      : DateTime.parse(json['checkedAt'] as String),
  source: json['source'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$GroceryListItemModelImplToJson(
  _$GroceryListItemModelImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'listId': instance.listId,
  'name': instance.name,
  'category': instance.category,
  'qty': instance.qty,
  'notes': instance.notes,
  'unit': instance.unit,
  'checked': instance.checked,
  'checkedAt': instance.checkedAt?.toIso8601String(),
  'source': instance.source,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};
