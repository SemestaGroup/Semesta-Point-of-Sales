// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'kategori_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

KategoriModel _$KategoriModelFromJson(Map<String, dynamic> json) {
  return _KategoriModel.fromJson(json);
}

/// @nodoc
mixin _$KategoriModel {
  @JsonKey(name: 'commodity_type_id', fromJson: _toInt)
  int get idKategori => throw _privateConstructorUsedError;
  @JsonKey(name: 'commondity_name')
  String? get namaKategori => throw _privateConstructorUsedError;
  @JsonKey(name: 'commondity_code')
  String? get commondityCode => throw _privateConstructorUsedError;
  String? get brand => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this KategoriModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of KategoriModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $KategoriModelCopyWith<KategoriModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $KategoriModelCopyWith<$Res> {
  factory $KategoriModelCopyWith(
          KategoriModel value, $Res Function(KategoriModel) then) =
      _$KategoriModelCopyWithImpl<$Res, KategoriModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'commodity_type_id', fromJson: _toInt) int idKategori,
      @JsonKey(name: 'commondity_name') String? namaKategori,
      @JsonKey(name: 'commondity_code') String? commondityCode,
      String? brand,
      String? note});
}

/// @nodoc
class _$KategoriModelCopyWithImpl<$Res, $Val extends KategoriModel>
    implements $KategoriModelCopyWith<$Res> {
  _$KategoriModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of KategoriModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idKategori = null,
    Object? namaKategori = freezed,
    Object? commondityCode = freezed,
    Object? brand = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      idKategori: null == idKategori
          ? _value.idKategori
          : idKategori // ignore: cast_nullable_to_non_nullable
              as int,
      namaKategori: freezed == namaKategori
          ? _value.namaKategori
          : namaKategori // ignore: cast_nullable_to_non_nullable
              as String?,
      commondityCode: freezed == commondityCode
          ? _value.commondityCode
          : commondityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$KategoriModelImplCopyWith<$Res>
    implements $KategoriModelCopyWith<$Res> {
  factory _$$KategoriModelImplCopyWith(
          _$KategoriModelImpl value, $Res Function(_$KategoriModelImpl) then) =
      __$$KategoriModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'commodity_type_id', fromJson: _toInt) int idKategori,
      @JsonKey(name: 'commondity_name') String? namaKategori,
      @JsonKey(name: 'commondity_code') String? commondityCode,
      String? brand,
      String? note});
}

/// @nodoc
class __$$KategoriModelImplCopyWithImpl<$Res>
    extends _$KategoriModelCopyWithImpl<$Res, _$KategoriModelImpl>
    implements _$$KategoriModelImplCopyWith<$Res> {
  __$$KategoriModelImplCopyWithImpl(
      _$KategoriModelImpl _value, $Res Function(_$KategoriModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of KategoriModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idKategori = null,
    Object? namaKategori = freezed,
    Object? commondityCode = freezed,
    Object? brand = freezed,
    Object? note = freezed,
  }) {
    return _then(_$KategoriModelImpl(
      idKategori: null == idKategori
          ? _value.idKategori
          : idKategori // ignore: cast_nullable_to_non_nullable
              as int,
      namaKategori: freezed == namaKategori
          ? _value.namaKategori
          : namaKategori // ignore: cast_nullable_to_non_nullable
              as String?,
      commondityCode: freezed == commondityCode
          ? _value.commondityCode
          : commondityCode // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: freezed == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$KategoriModelImpl implements _KategoriModel {
  const _$KategoriModelImpl(
      {@JsonKey(name: 'commodity_type_id', fromJson: _toInt)
      this.idKategori = 0,
      @JsonKey(name: 'commondity_name') this.namaKategori,
      @JsonKey(name: 'commondity_code') this.commondityCode,
      this.brand,
      this.note});

  factory _$KategoriModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$KategoriModelImplFromJson(json);

  @override
  @JsonKey(name: 'commodity_type_id', fromJson: _toInt)
  final int idKategori;
  @override
  @JsonKey(name: 'commondity_name')
  final String? namaKategori;
  @override
  @JsonKey(name: 'commondity_code')
  final String? commondityCode;
  @override
  final String? brand;
  @override
  final String? note;

  @override
  String toString() {
    return 'KategoriModel(idKategori: $idKategori, namaKategori: $namaKategori, commondityCode: $commondityCode, brand: $brand, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$KategoriModelImpl &&
            (identical(other.idKategori, idKategori) ||
                other.idKategori == idKategori) &&
            (identical(other.namaKategori, namaKategori) ||
                other.namaKategori == namaKategori) &&
            (identical(other.commondityCode, commondityCode) ||
                other.commondityCode == commondityCode) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, idKategori, namaKategori, commondityCode, brand, note);

  /// Create a copy of KategoriModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$KategoriModelImplCopyWith<_$KategoriModelImpl> get copyWith =>
      __$$KategoriModelImplCopyWithImpl<_$KategoriModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$KategoriModelImplToJson(
      this,
    );
  }
}

abstract class _KategoriModel implements KategoriModel {
  const factory _KategoriModel(
      {@JsonKey(name: 'commodity_type_id', fromJson: _toInt)
      final int idKategori,
      @JsonKey(name: 'commondity_name') final String? namaKategori,
      @JsonKey(name: 'commondity_code') final String? commondityCode,
      final String? brand,
      final String? note}) = _$KategoriModelImpl;

  factory _KategoriModel.fromJson(Map<String, dynamic> json) =
      _$KategoriModelImpl.fromJson;

  @override
  @JsonKey(name: 'commodity_type_id', fromJson: _toInt)
  int get idKategori;
  @override
  @JsonKey(name: 'commondity_name')
  String? get namaKategori;
  @override
  @JsonKey(name: 'commondity_code')
  String? get commondityCode;
  @override
  String? get brand;
  @override
  String? get note;

  /// Create a copy of KategoriModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$KategoriModelImplCopyWith<_$KategoriModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
