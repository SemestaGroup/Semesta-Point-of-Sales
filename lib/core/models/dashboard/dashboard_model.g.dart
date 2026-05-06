// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DashboardModelImpl _$$DashboardModelImplFromJson(Map<String, dynamic> json) =>
    _$DashboardModelImpl(
      kategori: (json['kategori'] as num?)?.toInt() ?? 0,
      produk: (json['produk'] as num?)?.toInt() ?? 0,
      supplier: (json['supplier'] as num?)?.toInt() ?? 0,
      member: (json['member'] as num?)?.toInt() ?? 0,
      tanggalAwal: json['tanggal_awal'] as String? ?? '',
      tanggalAkhir: json['tanggal_akhir'] as String? ?? '',
      dataTanggal: json['data_tanggal'] ?? const [],
      dataPendapatan: json['data_pendapatan'] ?? const [],
    );

Map<String, dynamic> _$$DashboardModelImplToJson(
        _$DashboardModelImpl instance) =>
    <String, dynamic>{
      'kategori': instance.kategori,
      'produk': instance.produk,
      'supplier': instance.supplier,
      'member': instance.member,
      'tanggal_awal': instance.tanggalAwal,
      'tanggal_akhir': instance.tanggalAkhir,
      'data_tanggal': instance.dataTanggal,
      'data_pendapatan': instance.dataPendapatan,
    };
