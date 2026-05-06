import 'package:freezed_annotation/freezed_annotation.dart';

part 'kategori_model.freezed.dart';
part 'kategori_model.g.dart';

@freezed
class KategoriModel with _$KategoriModel {
  const factory KategoriModel({
    @JsonKey(name: 'commodity_type_id', fromJson: _toInt) @Default(0) int idKategori,
    @JsonKey(name: 'commondity_name') String? namaKategori,
    @JsonKey(name: 'commondity_code') String? commondityCode,
    String? brand,
    String? note,
  }) = _KategoriModel;

  factory KategoriModel.fromJson(Map<String, dynamic> json) => _$KategoriModelFromJson(json);
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}
