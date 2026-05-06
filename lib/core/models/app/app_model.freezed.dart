// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppModel _$AppModelFromJson(Map<String, dynamic> json) {
  return _AppModel.fromJson(json);
}

/// @nodoc
mixin _$AppModel {
  @JsonKey(name: 'id_setting')
  int get idSetting => throw _privateConstructorUsedError;
  @JsonKey(name: 'nama_perusahaan')
  String get namaPerusahaan => throw _privateConstructorUsedError;
  String get alamat => throw _privateConstructorUsedError;
  String get telepon => throw _privateConstructorUsedError;
  @JsonKey(name: 'tipe_nota')
  int get tipeNota => throw _privateConstructorUsedError;
  int get diskon => throw _privateConstructorUsedError;
  @JsonKey(name: 'path_logo')
  String get pathLogo => throw _privateConstructorUsedError;
  @JsonKey(name: 'path_kartu_member')
  String get pathKartuMember => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  String get version => throw _privateConstructorUsedError;

  /// Serializes this AppModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppModelCopyWith<AppModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppModelCopyWith<$Res> {
  factory $AppModelCopyWith(AppModel value, $Res Function(AppModel) then) =
      _$AppModelCopyWithImpl<$Res, AppModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_setting') int idSetting,
      @JsonKey(name: 'nama_perusahaan') String namaPerusahaan,
      String alamat,
      String telepon,
      @JsonKey(name: 'tipe_nota') int tipeNota,
      int diskon,
      @JsonKey(name: 'path_logo') String pathLogo,
      @JsonKey(name: 'path_kartu_member') String pathKartuMember,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      String version});
}

/// @nodoc
class _$AppModelCopyWithImpl<$Res, $Val extends AppModel>
    implements $AppModelCopyWith<$Res> {
  _$AppModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idSetting = null,
    Object? namaPerusahaan = null,
    Object? alamat = null,
    Object? telepon = null,
    Object? tipeNota = null,
    Object? diskon = null,
    Object? pathLogo = null,
    Object? pathKartuMember = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? version = null,
  }) {
    return _then(_value.copyWith(
      idSetting: null == idSetting
          ? _value.idSetting
          : idSetting // ignore: cast_nullable_to_non_nullable
              as int,
      namaPerusahaan: null == namaPerusahaan
          ? _value.namaPerusahaan
          : namaPerusahaan // ignore: cast_nullable_to_non_nullable
              as String,
      alamat: null == alamat
          ? _value.alamat
          : alamat // ignore: cast_nullable_to_non_nullable
              as String,
      telepon: null == telepon
          ? _value.telepon
          : telepon // ignore: cast_nullable_to_non_nullable
              as String,
      tipeNota: null == tipeNota
          ? _value.tipeNota
          : tipeNota // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      pathLogo: null == pathLogo
          ? _value.pathLogo
          : pathLogo // ignore: cast_nullable_to_non_nullable
              as String,
      pathKartuMember: null == pathKartuMember
          ? _value.pathKartuMember
          : pathKartuMember // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppModelImplCopyWith<$Res>
    implements $AppModelCopyWith<$Res> {
  factory _$$AppModelImplCopyWith(
          _$AppModelImpl value, $Res Function(_$AppModelImpl) then) =
      __$$AppModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_setting') int idSetting,
      @JsonKey(name: 'nama_perusahaan') String namaPerusahaan,
      String alamat,
      String telepon,
      @JsonKey(name: 'tipe_nota') int tipeNota,
      int diskon,
      @JsonKey(name: 'path_logo') String pathLogo,
      @JsonKey(name: 'path_kartu_member') String pathKartuMember,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt,
      String version});
}

/// @nodoc
class __$$AppModelImplCopyWithImpl<$Res>
    extends _$AppModelCopyWithImpl<$Res, _$AppModelImpl>
    implements _$$AppModelImplCopyWith<$Res> {
  __$$AppModelImplCopyWithImpl(
      _$AppModelImpl _value, $Res Function(_$AppModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idSetting = null,
    Object? namaPerusahaan = null,
    Object? alamat = null,
    Object? telepon = null,
    Object? tipeNota = null,
    Object? diskon = null,
    Object? pathLogo = null,
    Object? pathKartuMember = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? version = null,
  }) {
    return _then(_$AppModelImpl(
      idSetting: null == idSetting
          ? _value.idSetting
          : idSetting // ignore: cast_nullable_to_non_nullable
              as int,
      namaPerusahaan: null == namaPerusahaan
          ? _value.namaPerusahaan
          : namaPerusahaan // ignore: cast_nullable_to_non_nullable
              as String,
      alamat: null == alamat
          ? _value.alamat
          : alamat // ignore: cast_nullable_to_non_nullable
              as String,
      telepon: null == telepon
          ? _value.telepon
          : telepon // ignore: cast_nullable_to_non_nullable
              as String,
      tipeNota: null == tipeNota
          ? _value.tipeNota
          : tipeNota // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      pathLogo: null == pathLogo
          ? _value.pathLogo
          : pathLogo // ignore: cast_nullable_to_non_nullable
              as String,
      pathKartuMember: null == pathKartuMember
          ? _value.pathKartuMember
          : pathKartuMember // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppModelImpl implements _AppModel {
  const _$AppModelImpl(
      {@JsonKey(name: 'id_setting') this.idSetting = 0,
      @JsonKey(name: 'nama_perusahaan') this.namaPerusahaan = "",
      this.alamat = "",
      this.telepon = "",
      @JsonKey(name: 'tipe_nota') this.tipeNota = 0,
      this.diskon = 0,
      @JsonKey(name: 'path_logo') this.pathLogo = "",
      @JsonKey(name: 'path_kartu_member') this.pathKartuMember = "",
      @JsonKey(name: 'created_at') this.createdAt = null,
      @JsonKey(name: 'updated_at') this.updatedAt = null,
      this.version = ""});

  factory _$AppModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppModelImplFromJson(json);

  @override
  @JsonKey(name: 'id_setting')
  final int idSetting;
  @override
  @JsonKey(name: 'nama_perusahaan')
  final String namaPerusahaan;
  @override
  @JsonKey()
  final String alamat;
  @override
  @JsonKey()
  final String telepon;
  @override
  @JsonKey(name: 'tipe_nota')
  final int tipeNota;
  @override
  @JsonKey()
  final int diskon;
  @override
  @JsonKey(name: 'path_logo')
  final String pathLogo;
  @override
  @JsonKey(name: 'path_kartu_member')
  final String pathKartuMember;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final String version;

  @override
  String toString() {
    return 'AppModel(idSetting: $idSetting, namaPerusahaan: $namaPerusahaan, alamat: $alamat, telepon: $telepon, tipeNota: $tipeNota, diskon: $diskon, pathLogo: $pathLogo, pathKartuMember: $pathKartuMember, createdAt: $createdAt, updatedAt: $updatedAt, version: $version)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppModelImpl &&
            (identical(other.idSetting, idSetting) ||
                other.idSetting == idSetting) &&
            (identical(other.namaPerusahaan, namaPerusahaan) ||
                other.namaPerusahaan == namaPerusahaan) &&
            (identical(other.alamat, alamat) || other.alamat == alamat) &&
            (identical(other.telepon, telepon) || other.telepon == telepon) &&
            (identical(other.tipeNota, tipeNota) ||
                other.tipeNota == tipeNota) &&
            (identical(other.diskon, diskon) || other.diskon == diskon) &&
            (identical(other.pathLogo, pathLogo) ||
                other.pathLogo == pathLogo) &&
            (identical(other.pathKartuMember, pathKartuMember) ||
                other.pathKartuMember == pathKartuMember) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.version, version) || other.version == version));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      idSetting,
      namaPerusahaan,
      alamat,
      telepon,
      tipeNota,
      diskon,
      pathLogo,
      pathKartuMember,
      createdAt,
      updatedAt,
      version);

  /// Create a copy of AppModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppModelImplCopyWith<_$AppModelImpl> get copyWith =>
      __$$AppModelImplCopyWithImpl<_$AppModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppModelImplToJson(
      this,
    );
  }
}

abstract class _AppModel implements AppModel {
  const factory _AppModel(
      {@JsonKey(name: 'id_setting') final int idSetting,
      @JsonKey(name: 'nama_perusahaan') final String namaPerusahaan,
      final String alamat,
      final String telepon,
      @JsonKey(name: 'tipe_nota') final int tipeNota,
      final int diskon,
      @JsonKey(name: 'path_logo') final String pathLogo,
      @JsonKey(name: 'path_kartu_member') final String pathKartuMember,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at') final DateTime? updatedAt,
      final String version}) = _$AppModelImpl;

  factory _AppModel.fromJson(Map<String, dynamic> json) =
      _$AppModelImpl.fromJson;

  @override
  @JsonKey(name: 'id_setting')
  int get idSetting;
  @override
  @JsonKey(name: 'nama_perusahaan')
  String get namaPerusahaan;
  @override
  String get alamat;
  @override
  String get telepon;
  @override
  @JsonKey(name: 'tipe_nota')
  int get tipeNota;
  @override
  int get diskon;
  @override
  @JsonKey(name: 'path_logo')
  String get pathLogo;
  @override
  @JsonKey(name: 'path_kartu_member')
  String get pathKartuMember;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  String get version;

  /// Create a copy of AppModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppModelImplCopyWith<_$AppModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
