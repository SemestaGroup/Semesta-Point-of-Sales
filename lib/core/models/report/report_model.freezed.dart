// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ReportModel _$ReportModelFromJson(Map<String, dynamic> json) {
  return _ReportModel.fromJson(json);
}

/// @nodoc
mixin _$ReportModel {
  @JsonKey(name: 'DT_RowIndex')
  dynamic get dtRowIndex => throw _privateConstructorUsedError;
  String get tanggal => throw _privateConstructorUsedError;
  String get penjualan => throw _privateConstructorUsedError;
  String get pembelian => throw _privateConstructorUsedError;
  String get pengeluaran => throw _privateConstructorUsedError;
  String get pendapatan => throw _privateConstructorUsedError;

  /// Serializes this ReportModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReportModelCopyWith<ReportModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReportModelCopyWith<$Res> {
  factory $ReportModelCopyWith(
          ReportModel value, $Res Function(ReportModel) then) =
      _$ReportModelCopyWithImpl<$Res, ReportModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'DT_RowIndex') dynamic dtRowIndex,
      String tanggal,
      String penjualan,
      String pembelian,
      String pengeluaran,
      String pendapatan});
}

/// @nodoc
class _$ReportModelCopyWithImpl<$Res, $Val extends ReportModel>
    implements $ReportModelCopyWith<$Res> {
  _$ReportModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dtRowIndex = freezed,
    Object? tanggal = null,
    Object? penjualan = null,
    Object? pembelian = null,
    Object? pengeluaran = null,
    Object? pendapatan = null,
  }) {
    return _then(_value.copyWith(
      dtRowIndex: freezed == dtRowIndex
          ? _value.dtRowIndex
          : dtRowIndex // ignore: cast_nullable_to_non_nullable
              as dynamic,
      tanggal: null == tanggal
          ? _value.tanggal
          : tanggal // ignore: cast_nullable_to_non_nullable
              as String,
      penjualan: null == penjualan
          ? _value.penjualan
          : penjualan // ignore: cast_nullable_to_non_nullable
              as String,
      pembelian: null == pembelian
          ? _value.pembelian
          : pembelian // ignore: cast_nullable_to_non_nullable
              as String,
      pengeluaran: null == pengeluaran
          ? _value.pengeluaran
          : pengeluaran // ignore: cast_nullable_to_non_nullable
              as String,
      pendapatan: null == pendapatan
          ? _value.pendapatan
          : pendapatan // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReportModelImplCopyWith<$Res>
    implements $ReportModelCopyWith<$Res> {
  factory _$$ReportModelImplCopyWith(
          _$ReportModelImpl value, $Res Function(_$ReportModelImpl) then) =
      __$$ReportModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'DT_RowIndex') dynamic dtRowIndex,
      String tanggal,
      String penjualan,
      String pembelian,
      String pengeluaran,
      String pendapatan});
}

/// @nodoc
class __$$ReportModelImplCopyWithImpl<$Res>
    extends _$ReportModelCopyWithImpl<$Res, _$ReportModelImpl>
    implements _$$ReportModelImplCopyWith<$Res> {
  __$$ReportModelImplCopyWithImpl(
      _$ReportModelImpl _value, $Res Function(_$ReportModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ReportModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dtRowIndex = freezed,
    Object? tanggal = null,
    Object? penjualan = null,
    Object? pembelian = null,
    Object? pengeluaran = null,
    Object? pendapatan = null,
  }) {
    return _then(_$ReportModelImpl(
      dtRowIndex: freezed == dtRowIndex
          ? _value.dtRowIndex
          : dtRowIndex // ignore: cast_nullable_to_non_nullable
              as dynamic,
      tanggal: null == tanggal
          ? _value.tanggal
          : tanggal // ignore: cast_nullable_to_non_nullable
              as String,
      penjualan: null == penjualan
          ? _value.penjualan
          : penjualan // ignore: cast_nullable_to_non_nullable
              as String,
      pembelian: null == pembelian
          ? _value.pembelian
          : pembelian // ignore: cast_nullable_to_non_nullable
              as String,
      pengeluaran: null == pengeluaran
          ? _value.pengeluaran
          : pengeluaran // ignore: cast_nullable_to_non_nullable
              as String,
      pendapatan: null == pendapatan
          ? _value.pendapatan
          : pendapatan // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReportModelImpl implements _ReportModel {
  const _$ReportModelImpl(
      {@JsonKey(name: 'DT_RowIndex') this.dtRowIndex,
      this.tanggal = '0',
      this.penjualan = '0',
      this.pembelian = '0',
      this.pengeluaran = '0',
      this.pendapatan = '0'});

  factory _$ReportModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReportModelImplFromJson(json);

  @override
  @JsonKey(name: 'DT_RowIndex')
  final dynamic dtRowIndex;
  @override
  @JsonKey()
  final String tanggal;
  @override
  @JsonKey()
  final String penjualan;
  @override
  @JsonKey()
  final String pembelian;
  @override
  @JsonKey()
  final String pengeluaran;
  @override
  @JsonKey()
  final String pendapatan;

  @override
  String toString() {
    return 'ReportModel(dtRowIndex: $dtRowIndex, tanggal: $tanggal, penjualan: $penjualan, pembelian: $pembelian, pengeluaran: $pengeluaran, pendapatan: $pendapatan)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReportModelImpl &&
            const DeepCollectionEquality()
                .equals(other.dtRowIndex, dtRowIndex) &&
            (identical(other.tanggal, tanggal) || other.tanggal == tanggal) &&
            (identical(other.penjualan, penjualan) ||
                other.penjualan == penjualan) &&
            (identical(other.pembelian, pembelian) ||
                other.pembelian == pembelian) &&
            (identical(other.pengeluaran, pengeluaran) ||
                other.pengeluaran == pengeluaran) &&
            (identical(other.pendapatan, pendapatan) ||
                other.pendapatan == pendapatan));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(dtRowIndex),
      tanggal,
      penjualan,
      pembelian,
      pengeluaran,
      pendapatan);

  /// Create a copy of ReportModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReportModelImplCopyWith<_$ReportModelImpl> get copyWith =>
      __$$ReportModelImplCopyWithImpl<_$ReportModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReportModelImplToJson(
      this,
    );
  }
}

abstract class _ReportModel implements ReportModel {
  const factory _ReportModel(
      {@JsonKey(name: 'DT_RowIndex') final dynamic dtRowIndex,
      final String tanggal,
      final String penjualan,
      final String pembelian,
      final String pengeluaran,
      final String pendapatan}) = _$ReportModelImpl;

  factory _ReportModel.fromJson(Map<String, dynamic> json) =
      _$ReportModelImpl.fromJson;

  @override
  @JsonKey(name: 'DT_RowIndex')
  dynamic get dtRowIndex;
  @override
  String get tanggal;
  @override
  String get penjualan;
  @override
  String get pembelian;
  @override
  String get pengeluaran;
  @override
  String get pendapatan;

  /// Create a copy of ReportModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReportModelImplCopyWith<_$ReportModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
