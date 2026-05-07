import 'package:freezed_annotation/freezed_annotation.dart';
part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    @JsonKey(name: 'id', fromJson: _toInt) @Default(0) int idProduk,
    @JsonKey(name: 'category_id', fromJson: _toInt) @Default(0) int idKategori,
    @JsonKey(name: 'sku') String? kodeProduk,
    @JsonKey(name: 'name') String? namaProduk,
    String? merk,
    @JsonKey(name: 'cost', fromJson: _toInt) @Default(0) int hargaBeli,
    @Default(0) int diskon,
    @JsonKey(name: 'price', fromJson: _toInt) @Default(0) int hargaJual,
    @JsonKey(name: 'stock_quantity', fromJson: _toInt) @Default(0) int stok,
    @JsonKey(name: 'image_url') String? img,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'nama_kategori') String? namaKategori,
    @JsonKey(name: 'order_types') String? orderTypes,
    @JsonKey(name: 'discount_total', fromJson: _toInt) @Default(0) int discountTotal,
    @JsonKey(name: 'discount_type') @Default('percent') String discountType,
    @Default('active') String status,
    @JsonKey(name: 'parent') String? parent,
    @JsonKey(name: 'children') String? children,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
