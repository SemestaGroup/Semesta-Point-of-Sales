// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_mode_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaymentModeModelImpl _$$PaymentModeModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PaymentModeModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      active: json['active'] as String,
      selectedByDefault: json['selected_by_default'] as String?,
    );

Map<String, dynamic> _$$PaymentModeModelImplToJson(
        _$PaymentModeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'active': instance.active,
      'selected_by_default': instance.selectedByDefault,
    };
