import 'package:freezed_annotation/freezed_annotation.dart';

part 'brand_model.freezed.dart';
part 'brand_model.g.dart';

@freezed
class BrandModel with _$BrandModel {
  const factory BrandModel({
    @JsonKey(name: 'id', fromJson: _toInt) @Default(0) int idBrand,
    @JsonKey(name: 'name') String? namaBrand,
    @JsonKey(name: 'commodity_group_code') String? commodityGroupCode,
    String? display,
    String? note,
  }) = _BrandModel;

  factory BrandModel.fromJson(Map<String, dynamic> json) =>
      _$BrandModelFromJson(json);
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
