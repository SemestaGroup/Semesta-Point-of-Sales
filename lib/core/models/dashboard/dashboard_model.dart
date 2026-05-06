import 'package:freezed_annotation/freezed_annotation.dart';

part 'dashboard_model.freezed.dart';
part 'dashboard_model.g.dart';

@freezed
class DashboardModel with _$DashboardModel {
  const factory DashboardModel({
    @Default(0) int kategori,
    @Default(0) int produk,
    @Default(0) int supplier,
    @Default(0) int member,
    @JsonKey(name: 'tanggal_awal') @Default('') String tanggalAwal,
    @JsonKey(name: 'tanggal_akhir') @Default('') String tanggalAkhir,
    @JsonKey(name: 'data_tanggal') @Default([]) dynamic dataTanggal,
    @JsonKey(name: 'data_pendapatan') @Default([]) dynamic dataPendapatan,
  }) = _DashboardModel;

  factory DashboardModel.fromJson(Map<String, dynamic> json) =>
      _$DashboardModelFromJson(json);
}
