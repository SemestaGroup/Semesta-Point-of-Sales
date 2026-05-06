// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'brand_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

BrandModel _$BrandModelFromJson(Map<String, dynamic> json) {
  return _BrandModel.fromJson(json);
}

/// @nodoc
mixin _$BrandModel {
  @JsonKey(name: 'id', fromJson: _toInt)
  int get idBrand => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String? get namaBrand => throw _privateConstructorUsedError;
  @JsonKey(name: 'commodity_group_code')
  String? get commodityGroupCode => throw _privateConstructorUsedError;
  String? get display => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this BrandModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BrandModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BrandModelCopyWith<BrandModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BrandModelCopyWith<$Res> {
  factory $BrandModelCopyWith(
          BrandModel value, $Res Function(BrandModel) then) =
      _$BrandModelCopyWithImpl<$Res, BrandModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _toInt) int idBrand,
      @JsonKey(name: 'name') String? namaBrand,
      @JsonKey(name: 'commodity_group_code') String? commodityGroupCode,
      String? display,
      String? note});
}

/// @nodoc
class _$BrandModelCopyWithImpl<$Res, $Val extends BrandModel>
    implements $BrandModelCopyWith<$Res> {
  _$BrandModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BrandModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idBrand = null,
    Object? namaBrand = freezed,
    Object? commodityGroupCode = freezed,
    Object? display = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      idBrand: null == idBrand
          ? _value.idBrand
          : idBrand // ignore: cast_nullable_to_non_nullable
              as int,
      namaBrand: freezed == namaBrand
          ? _value.namaBrand
          : namaBrand // ignore: cast_nullable_to_non_nullable
              as String?,
      commodityGroupCode: freezed == commodityGroupCode
          ? _value.commodityGroupCode
          : commodityGroupCode // ignore: cast_nullable_to_non_nullable
              as String?,
      display: freezed == display
          ? _value.display
          : display // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BrandModelImplCopyWith<$Res>
    implements $BrandModelCopyWith<$Res> {
  factory _$$BrandModelImplCopyWith(
          _$BrandModelImpl value, $Res Function(_$BrandModelImpl) then) =
      __$$BrandModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _toInt) int idBrand,
      @JsonKey(name: 'name') String? namaBrand,
      @JsonKey(name: 'commodity_group_code') String? commodityGroupCode,
      String? display,
      String? note});
}

/// @nodoc
class __$$BrandModelImplCopyWithImpl<$Res>
    extends _$BrandModelCopyWithImpl<$Res, _$BrandModelImpl>
    implements _$$BrandModelImplCopyWith<$Res> {
  __$$BrandModelImplCopyWithImpl(
      _$BrandModelImpl _value, $Res Function(_$BrandModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of BrandModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idBrand = null,
    Object? namaBrand = freezed,
    Object? commodityGroupCode = freezed,
    Object? display = freezed,
    Object? note = freezed,
  }) {
    return _then(_$BrandModelImpl(
      idBrand: null == idBrand
          ? _value.idBrand
          : idBrand // ignore: cast_nullable_to_non_nullable
              as int,
      namaBrand: freezed == namaBrand
          ? _value.namaBrand
          : namaBrand // ignore: cast_nullable_to_non_nullable
              as String?,
      commodityGroupCode: freezed == commodityGroupCode
          ? _value.commodityGroupCode
          : commodityGroupCode // ignore: cast_nullable_to_non_nullable
              as String?,
      display: freezed == display
          ? _value.display
          : display // ignore: cast_nullable_to_non_nullable
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
class _$BrandModelImpl implements _BrandModel {
  const _$BrandModelImpl(
      {@JsonKey(name: 'id', fromJson: _toInt) this.idBrand = 0,
      @JsonKey(name: 'name') this.namaBrand,
      @JsonKey(name: 'commodity_group_code') this.commodityGroupCode,
      this.display,
      this.note});

  factory _$BrandModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BrandModelImplFromJson(json);

  @override
  @JsonKey(name: 'id', fromJson: _toInt)
  final int idBrand;
  @override
  @JsonKey(name: 'name')
  final String? namaBrand;
  @override
  @JsonKey(name: 'commodity_group_code')
  final String? commodityGroupCode;
  @override
  final String? display;
  @override
  final String? note;

  @override
  String toString() {
    return 'BrandModel(idBrand: $idBrand, namaBrand: $namaBrand, commodityGroupCode: $commodityGroupCode, display: $display, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BrandModelImpl &&
            (identical(other.idBrand, idBrand) || other.idBrand == idBrand) &&
            (identical(other.namaBrand, namaBrand) ||
                other.namaBrand == namaBrand) &&
            (identical(other.commodityGroupCode, commodityGroupCode) ||
                other.commodityGroupCode == commodityGroupCode) &&
            (identical(other.display, display) || other.display == display) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, idBrand, namaBrand, commodityGroupCode, display, note);

  /// Create a copy of BrandModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BrandModelImplCopyWith<_$BrandModelImpl> get copyWith =>
      __$$BrandModelImplCopyWithImpl<_$BrandModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BrandModelImplToJson(
      this,
    );
  }
}

abstract class _BrandModel implements BrandModel {
  const factory _BrandModel(
      {@JsonKey(name: 'id', fromJson: _toInt) final int idBrand,
      @JsonKey(name: 'name') final String? namaBrand,
      @JsonKey(name: 'commodity_group_code') final String? commodityGroupCode,
      final String? display,
      final String? note}) = _$BrandModelImpl;

  factory _BrandModel.fromJson(Map<String, dynamic> json) =
      _$BrandModelImpl.fromJson;

  @override
  @JsonKey(name: 'id', fromJson: _toInt)
  int get idBrand;
  @override
  @JsonKey(name: 'name')
  String? get namaBrand;
  @override
  @JsonKey(name: 'commodity_group_code')
  String? get commodityGroupCode;
  @override
  String? get display;
  @override
  String? get note;

  /// Create a copy of BrandModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BrandModelImplCopyWith<_$BrandModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
