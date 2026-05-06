// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProductModelImpl _$$ProductModelImplFromJson(Map<String, dynamic> json) =>
    _$ProductModelImpl(
      idProduk: json['id'] == null ? 0 : _toInt(json['id']),
      idKategori: json['category_id'] == null ? 0 : _toInt(json['category_id']),
      kodeProduk: json['sku'] as String?,
      namaProduk: json['name'] as String?,
      merk: json['merk'] as String?,
      hargaBeli: json['cost'] == null ? 0 : _toInt(json['cost']),
      diskon: (json['diskon'] as num?)?.toInt() ?? 0,
      hargaJual: json['price'] == null ? 0 : _toInt(json['price']),
      stok: json['stock_quantity'] == null ? 0 : _toInt(json['stock_quantity']),
      img: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      namaKategori: json['nama_kategori'] as String?,
      orderTypes: json['order_types'] as String?,
      discountTotal:
          json['discount_total'] == null ? 0 : _toInt(json['discount_total']),
      discountType: json['discount_type'] as String? ?? 'percent',
      status: json['status'] as String? ?? 'active',
    );

Map<String, dynamic> _$$ProductModelImplToJson(_$ProductModelImpl instance) =>
    <String, dynamic>{
      'id': instance.idProduk,
      'category_id': instance.idKategori,
      'sku': instance.kodeProduk,
      'name': instance.namaProduk,
      'merk': instance.merk,
      'cost': instance.hargaBeli,
      'diskon': instance.diskon,
      'price': instance.hargaJual,
      'stock_quantity': instance.stok,
      'image_url': instance.img,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'nama_kategori': instance.namaKategori,
      'order_types': instance.orderTypes,
      'discount_total': instance.discountTotal,
      'discount_type': instance.discountType,
      'status': instance.status,
    };
