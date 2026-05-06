// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppModelImpl _$$AppModelImplFromJson(Map<String, dynamic> json) =>
    _$AppModelImpl(
      idSetting: (json['id_setting'] as num?)?.toInt() ?? 0,
      namaPerusahaan: json['nama_perusahaan'] as String? ?? "",
      alamat: json['alamat'] as String? ?? "",
      telepon: json['telepon'] as String? ?? "",
      tipeNota: (json['tipe_nota'] as num?)?.toInt() ?? 0,
      diskon: (json['diskon'] as num?)?.toInt() ?? 0,
      pathLogo: json['path_logo'] as String? ?? "",
      pathKartuMember: json['path_kartu_member'] as String? ?? "",
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      version: json['version'] as String? ?? "",
    );

Map<String, dynamic> _$$AppModelImplToJson(_$AppModelImpl instance) =>
    <String, dynamic>{
      'id_setting': instance.idSetting,
      'nama_perusahaan': instance.namaPerusahaan,
      'alamat': instance.alamat,
      'telepon': instance.telepon,
      'tipe_nota': instance.tipeNota,
      'diskon': instance.diskon,
      'path_logo': instance.pathLogo,
      'path_kartu_member': instance.pathKartuMember,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'version': instance.version,
    };
