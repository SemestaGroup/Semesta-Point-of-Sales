// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'brand_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BrandModelImpl _$$BrandModelImplFromJson(Map<String, dynamic> json) =>
    _$BrandModelImpl(
      idBrand: json['id'] == null ? 0 : _toInt(json['id']),
      namaBrand: json['name'] as String?,
      commodityGroupCode: json['commodity_group_code'] as String?,
      display: json['display'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$BrandModelImplToJson(_$BrandModelImpl instance) =>
    <String, dynamic>{
      'id': instance.idBrand,
      'name': instance.namaBrand,
      'commodity_group_code': instance.commodityGroupCode,
      'display': instance.display,
      'note': instance.note,
    };
