// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'penjualan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PenjualanModelImpl _$$PenjualanModelImplFromJson(Map<String, dynamic> json) =>
    _$PenjualanModelImpl(
      idPenjualan: (json['id_penjualan'] as num?)?.toInt() ?? 0,
      idMember: (json['id_member'] as num?)?.toInt() ?? 0,
      totalItem: (json['total_item'] as num?)?.toInt() ?? 0,
      totalHarga: (json['total_harga'] as num?)?.toInt() ?? 0,
      diskon: (json['diskon'] as num?)?.toInt() ?? 0,
      bayar: (json['bayar'] as num?)?.toInt() ?? 0,
      diterima: (json['diterima'] as num?)?.toInt() ?? 0,
      idUser: (json['id_user'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      idPos: json['id_pos'] as String?,
      orderType: json['order_type'] as String?,
      orderNote: json['order_note'] as String?,
      discountType: json['discount_type'] as String? ?? 'percent',
      manualDiscountValue:
          (json['manual_discount_value'] as num?)?.toInt() ?? 0,
      remoteNumber: json['remote_number'] as String?,
      queueNumber: (json['queue_number'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PenjualanModelImplToJson(
        _$PenjualanModelImpl instance) =>
    <String, dynamic>{
      'id_penjualan': instance.idPenjualan,
      'id_member': instance.idMember,
      'total_item': instance.totalItem,
      'total_harga': instance.totalHarga,
      'diskon': instance.diskon,
      'bayar': instance.bayar,
      'diterima': instance.diterima,
      'id_user': instance.idUser,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'id_pos': instance.idPos,
      'order_type': instance.orderType,
      'order_note': instance.orderNote,
      'discount_type': instance.discountType,
      'manual_discount_value': instance.manualDiscountValue,
      'remote_number': instance.remoteNumber,
      'queue_number': instance.queueNumber,
    };
