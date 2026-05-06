// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kategori_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KategoriModelImpl _$$KategoriModelImplFromJson(Map<String, dynamic> json) =>
    _$KategoriModelImpl(
      idKategori: json['commodity_type_id'] == null
          ? 0
          : _toInt(json['commodity_type_id']),
      namaKategori: json['commondity_name'] as String?,
      commondityCode: json['commondity_code'] as String?,
      brand: json['brand'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$KategoriModelImplToJson(_$KategoriModelImpl instance) =>
    <String, dynamic>{
      'commodity_type_id': instance.idKategori,
      'commondity_name': instance.namaKategori,
      'commondity_code': instance.commondityCode,
      'brand': instance.brand,
      'note': instance.note,
    };
