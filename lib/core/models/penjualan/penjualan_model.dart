import 'package:freezed_annotation/freezed_annotation.dart';
part 'penjualan_model.freezed.dart';
part 'penjualan_model.g.dart';

@freezed
class PenjualanModel with _$PenjualanModel {
  const factory PenjualanModel({
    @JsonKey(name: 'id_penjualan') @Default(0) int idPenjualan,
    @JsonKey(name: 'id_member') @Default(0) int idMember,
    @JsonKey(name: 'total_item') @Default(0) int totalItem,
    @JsonKey(name: 'total_harga') @Default(0) int totalHarga,
    @Default(0) int diskon,
    @Default(0) int bayar,
    @Default(0) int diterima,
    @JsonKey(name: 'id_user') @Default(0) int idUser,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'id_pos') String? idPos,
    @JsonKey(name: 'order_type') String? orderType,
    @JsonKey(name: 'order_note') String? orderNote,
    @JsonKey(name: 'discount_type') @Default('percent') String discountType,
    @JsonKey(name: 'manual_discount_value') @Default(0) int manualDiscountValue,
    @JsonKey(name: 'remote_number') String? remoteNumber,
    @JsonKey(name: 'queue_number') @Default(0) int queueNumber,
  }) = _PenjualanModel;

  factory PenjualanModel.fromJson(Map<String, dynamic> json) =>
      _$PenjualanModelFromJson(json);
}
