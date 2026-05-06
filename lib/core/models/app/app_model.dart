import 'package:freezed_annotation/freezed_annotation.dart';
part 'app_model.g.dart';
part 'app_model.freezed.dart';

@freezed
class AppModel with _$AppModel {
  const factory AppModel({
    @JsonKey(name: 'id_setting') @Default(0) int idSetting,
    @JsonKey(name: 'nama_perusahaan') @Default("") String namaPerusahaan,
    @Default("") String alamat,
    @Default("") String telepon,
    @JsonKey(name: 'tipe_nota') @Default(0) int tipeNota,
    @Default(0) int diskon,
    @JsonKey(name: 'path_logo') @Default("") String pathLogo,
    @JsonKey(name: 'path_kartu_member') @Default("") String pathKartuMember,
    @JsonKey(name: 'created_at') @Default(null) DateTime? createdAt,
    @JsonKey(name: 'updated_at') @Default(null) DateTime? updatedAt,
    @Default("") String version,
  }) = _AppModel;

  factory AppModel.fromJson(Map<String, dynamic> json) =>
      _$AppModelFromJson(json);
}
