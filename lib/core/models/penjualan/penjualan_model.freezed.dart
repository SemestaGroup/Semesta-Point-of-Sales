// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'penjualan_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PenjualanModel _$PenjualanModelFromJson(Map<String, dynamic> json) {
  return _PenjualanModel.fromJson(json);
}

/// @nodoc
mixin _$PenjualanModel {
  @JsonKey(name: 'id_penjualan')
  int get idPenjualan => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_member')
  int get idMember => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_item')
  int get totalItem => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_harga')
  int get totalHarga => throw _privateConstructorUsedError;
  int get diskon => throw _privateConstructorUsedError;
  int get bayar => throw _privateConstructorUsedError;
  int get diterima => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_user')
  int get idUser => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_pos')
  String? get idPos => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_type')
  String? get orderType => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_note')
  String? get orderNote => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_type')
  String get discountType => throw _privateConstructorUsedError;
  @JsonKey(name: 'manual_discount_value')
  int get manualDiscountValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'remote_number')
  String? get remoteNumber => throw _privateConstructorUsedError;
  @JsonKey(name: 'queue_number')
  int get queueNumber => throw _privateConstructorUsedError;

  /// Serializes this PenjualanModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PenjualanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PenjualanModelCopyWith<PenjualanModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PenjualanModelCopyWith<$Res> {
  factory $PenjualanModelCopyWith(
          PenjualanModel value, $Res Function(PenjualanModel) then) =
      _$PenjualanModelCopyWithImpl<$Res, PenjualanModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id_penjualan') int idPenjualan,
      @JsonKey(name: 'id_member') int idMember,
      @JsonKey(name: 'total_item') int totalItem,
      @JsonKey(name: 'total_harga') int totalHarga,
      int diskon,
      int bayar,
      int diterima,
      @JsonKey(name: 'id_user') int idUser,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      @JsonKey(name: 'id_pos') String? idPos,
      @JsonKey(name: 'order_type') String? orderType,
      @JsonKey(name: 'order_note') String? orderNote,
      @JsonKey(name: 'discount_type') String discountType,
      @JsonKey(name: 'manual_discount_value') int manualDiscountValue,
      @JsonKey(name: 'remote_number') String? remoteNumber,
      @JsonKey(name: 'queue_number') int queueNumber});
}

/// @nodoc
class _$PenjualanModelCopyWithImpl<$Res, $Val extends PenjualanModel>
    implements $PenjualanModelCopyWith<$Res> {
  _$PenjualanModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PenjualanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idPenjualan = null,
    Object? idMember = null,
    Object? totalItem = null,
    Object? totalHarga = null,
    Object? diskon = null,
    Object? bayar = null,
    Object? diterima = null,
    Object? idUser = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? idPos = freezed,
    Object? orderType = freezed,
    Object? orderNote = freezed,
    Object? discountType = null,
    Object? manualDiscountValue = null,
    Object? remoteNumber = freezed,
    Object? queueNumber = null,
  }) {
    return _then(_value.copyWith(
      idPenjualan: null == idPenjualan
          ? _value.idPenjualan
          : idPenjualan // ignore: cast_nullable_to_non_nullable
              as int,
      idMember: null == idMember
          ? _value.idMember
          : idMember // ignore: cast_nullable_to_non_nullable
              as int,
      totalItem: null == totalItem
          ? _value.totalItem
          : totalItem // ignore: cast_nullable_to_non_nullable
              as int,
      totalHarga: null == totalHarga
          ? _value.totalHarga
          : totalHarga // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      bayar: null == bayar
          ? _value.bayar
          : bayar // ignore: cast_nullable_to_non_nullable
              as int,
      diterima: null == diterima
          ? _value.diterima
          : diterima // ignore: cast_nullable_to_non_nullable
              as int,
      idUser: null == idUser
          ? _value.idUser
          : idUser // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      idPos: freezed == idPos
          ? _value.idPos
          : idPos // ignore: cast_nullable_to_non_nullable
              as String?,
      orderType: freezed == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNote: freezed == orderNote
          ? _value.orderNote
          : orderNote // ignore: cast_nullable_to_non_nullable
              as String?,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      manualDiscountValue: null == manualDiscountValue
          ? _value.manualDiscountValue
          : manualDiscountValue // ignore: cast_nullable_to_non_nullable
              as int,
      remoteNumber: freezed == remoteNumber
          ? _value.remoteNumber
          : remoteNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: null == queueNumber
          ? _value.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PenjualanModelImplCopyWith<$Res>
    implements $PenjualanModelCopyWith<$Res> {
  factory _$$PenjualanModelImplCopyWith(_$PenjualanModelImpl value,
          $Res Function(_$PenjualanModelImpl) then) =
      __$$PenjualanModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id_penjualan') int idPenjualan,
      @JsonKey(name: 'id_member') int idMember,
      @JsonKey(name: 'total_item') int totalItem,
      @JsonKey(name: 'total_harga') int totalHarga,
      int diskon,
      int bayar,
      int diterima,
      @JsonKey(name: 'id_user') int idUser,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      @JsonKey(name: 'id_pos') String? idPos,
      @JsonKey(name: 'order_type') String? orderType,
      @JsonKey(name: 'order_note') String? orderNote,
      @JsonKey(name: 'discount_type') String discountType,
      @JsonKey(name: 'manual_discount_value') int manualDiscountValue,
      @JsonKey(name: 'remote_number') String? remoteNumber,
      @JsonKey(name: 'queue_number') int queueNumber});
}

/// @nodoc
class __$$PenjualanModelImplCopyWithImpl<$Res>
    extends _$PenjualanModelCopyWithImpl<$Res, _$PenjualanModelImpl>
    implements _$$PenjualanModelImplCopyWith<$Res> {
  __$$PenjualanModelImplCopyWithImpl(
      _$PenjualanModelImpl _value, $Res Function(_$PenjualanModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PenjualanModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idPenjualan = null,
    Object? idMember = null,
    Object? totalItem = null,
    Object? totalHarga = null,
    Object? diskon = null,
    Object? bayar = null,
    Object? diterima = null,
    Object? idUser = null,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? idPos = freezed,
    Object? orderType = freezed,
    Object? orderNote = freezed,
    Object? discountType = null,
    Object? manualDiscountValue = null,
    Object? remoteNumber = freezed,
    Object? queueNumber = null,
  }) {
    return _then(_$PenjualanModelImpl(
      idPenjualan: null == idPenjualan
          ? _value.idPenjualan
          : idPenjualan // ignore: cast_nullable_to_non_nullable
              as int,
      idMember: null == idMember
          ? _value.idMember
          : idMember // ignore: cast_nullable_to_non_nullable
              as int,
      totalItem: null == totalItem
          ? _value.totalItem
          : totalItem // ignore: cast_nullable_to_non_nullable
              as int,
      totalHarga: null == totalHarga
          ? _value.totalHarga
          : totalHarga // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      bayar: null == bayar
          ? _value.bayar
          : bayar // ignore: cast_nullable_to_non_nullable
              as int,
      diterima: null == diterima
          ? _value.diterima
          : diterima // ignore: cast_nullable_to_non_nullable
              as int,
      idUser: null == idUser
          ? _value.idUser
          : idUser // ignore: cast_nullable_to_non_nullable
              as int,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      idPos: freezed == idPos
          ? _value.idPos
          : idPos // ignore: cast_nullable_to_non_nullable
              as String?,
      orderType: freezed == orderType
          ? _value.orderType
          : orderType // ignore: cast_nullable_to_non_nullable
              as String?,
      orderNote: freezed == orderNote
          ? _value.orderNote
          : orderNote // ignore: cast_nullable_to_non_nullable
              as String?,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      manualDiscountValue: null == manualDiscountValue
          ? _value.manualDiscountValue
          : manualDiscountValue // ignore: cast_nullable_to_non_nullable
              as int,
      remoteNumber: freezed == remoteNumber
          ? _value.remoteNumber
          : remoteNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      queueNumber: null == queueNumber
          ? _value.queueNumber
          : queueNumber // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PenjualanModelImpl implements _PenjualanModel {
  const _$PenjualanModelImpl(
      {@JsonKey(name: 'id_penjualan') this.idPenjualan = 0,
      @JsonKey(name: 'id_member') this.idMember = 0,
      @JsonKey(name: 'total_item') this.totalItem = 0,
      @JsonKey(name: 'total_harga') this.totalHarga = 0,
      this.diskon = 0,
      this.bayar = 0,
      this.diterima = 0,
      @JsonKey(name: 'id_user') this.idUser = 0,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'id_pos') this.idPos,
      @JsonKey(name: 'order_type') this.orderType,
      @JsonKey(name: 'order_note') this.orderNote,
      @JsonKey(name: 'discount_type') this.discountType = 'percent',
      @JsonKey(name: 'manual_discount_value') this.manualDiscountValue = 0,
      @JsonKey(name: 'remote_number') this.remoteNumber,
      @JsonKey(name: 'queue_number') this.queueNumber = 0});

  factory _$PenjualanModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PenjualanModelImplFromJson(json);

  @override
  @JsonKey(name: 'id_penjualan')
  final int idPenjualan;
  @override
  @JsonKey(name: 'id_member')
  final int idMember;
  @override
  @JsonKey(name: 'total_item')
  final int totalItem;
  @override
  @JsonKey(name: 'total_harga')
  final int totalHarga;
  @override
  @JsonKey()
  final int diskon;
  @override
  @JsonKey()
  final int bayar;
  @override
  @JsonKey()
  final int diterima;
  @override
  @JsonKey(name: 'id_user')
  final int idUser;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @override
  @JsonKey(name: 'id_pos')
  final String? idPos;
  @override
  @JsonKey(name: 'order_type')
  final String? orderType;
  @override
  @JsonKey(name: 'order_note')
  final String? orderNote;
  @override
  @JsonKey(name: 'discount_type')
  final String discountType;
  @override
  @JsonKey(name: 'manual_discount_value')
  final int manualDiscountValue;
  @override
  @JsonKey(name: 'remote_number')
  final String? remoteNumber;
  @override
  @JsonKey(name: 'queue_number')
  final int queueNumber;

  @override
  String toString() {
    return 'PenjualanModel(idPenjualan: $idPenjualan, idMember: $idMember, totalItem: $totalItem, totalHarga: $totalHarga, diskon: $diskon, bayar: $bayar, diterima: $diterima, idUser: $idUser, createdAt: $createdAt, updatedAt: $updatedAt, idPos: $idPos, orderType: $orderType, orderNote: $orderNote, discountType: $discountType, manualDiscountValue: $manualDiscountValue, remoteNumber: $remoteNumber, queueNumber: $queueNumber)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PenjualanModelImpl &&
            (identical(other.idPenjualan, idPenjualan) ||
                other.idPenjualan == idPenjualan) &&
            (identical(other.idMember, idMember) ||
                other.idMember == idMember) &&
            (identical(other.totalItem, totalItem) ||
                other.totalItem == totalItem) &&
            (identical(other.totalHarga, totalHarga) ||
                other.totalHarga == totalHarga) &&
            (identical(other.diskon, diskon) || other.diskon == diskon) &&
            (identical(other.bayar, bayar) || other.bayar == bayar) &&
            (identical(other.diterima, diterima) ||
                other.diterima == diterima) &&
            (identical(other.idUser, idUser) || other.idUser == idUser) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.idPos, idPos) || other.idPos == idPos) &&
            (identical(other.orderType, orderType) ||
                other.orderType == orderType) &&
            (identical(other.orderNote, orderNote) ||
                other.orderNote == orderNote) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.manualDiscountValue, manualDiscountValue) ||
                other.manualDiscountValue == manualDiscountValue) &&
            (identical(other.remoteNumber, remoteNumber) ||
                other.remoteNumber == remoteNumber) &&
            (identical(other.queueNumber, queueNumber) ||
                other.queueNumber == queueNumber));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      idPenjualan,
      idMember,
      totalItem,
      totalHarga,
      diskon,
      bayar,
      diterima,
      idUser,
      createdAt,
      updatedAt,
      idPos,
      orderType,
      orderNote,
      discountType,
      manualDiscountValue,
      remoteNumber,
      queueNumber);

  /// Create a copy of PenjualanModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PenjualanModelImplCopyWith<_$PenjualanModelImpl> get copyWith =>
      __$$PenjualanModelImplCopyWithImpl<_$PenjualanModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PenjualanModelImplToJson(
      this,
    );
  }
}

abstract class _PenjualanModel implements PenjualanModel {
  const factory _PenjualanModel(
          {@JsonKey(name: 'id_penjualan') final int idPenjualan,
          @JsonKey(name: 'id_member') final int idMember,
          @JsonKey(name: 'total_item') final int totalItem,
          @JsonKey(name: 'total_harga') final int totalHarga,
          final int diskon,
          final int bayar,
          final int diterima,
          @JsonKey(name: 'id_user') final int idUser,
          @JsonKey(name: 'created_at') final String? createdAt,
          @JsonKey(name: 'updated_at') final String? updatedAt,
          @JsonKey(name: 'id_pos') final String? idPos,
          @JsonKey(name: 'order_type') final String? orderType,
          @JsonKey(name: 'order_note') final String? orderNote,
          @JsonKey(name: 'discount_type') final String discountType,
          @JsonKey(name: 'manual_discount_value') final int manualDiscountValue,
          @JsonKey(name: 'remote_number') final String? remoteNumber,
          @JsonKey(name: 'queue_number') final int queueNumber}) =
      _$PenjualanModelImpl;

  factory _PenjualanModel.fromJson(Map<String, dynamic> json) =
      _$PenjualanModelImpl.fromJson;

  @override
  @JsonKey(name: 'id_penjualan')
  int get idPenjualan;
  @override
  @JsonKey(name: 'id_member')
  int get idMember;
  @override
  @JsonKey(name: 'total_item')
  int get totalItem;
  @override
  @JsonKey(name: 'total_harga')
  int get totalHarga;
  @override
  int get diskon;
  @override
  int get bayar;
  @override
  int get diterima;
  @override
  @JsonKey(name: 'id_user')
  int get idUser;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;
  @override
  @JsonKey(name: 'id_pos')
  String? get idPos;
  @override
  @JsonKey(name: 'order_type')
  String? get orderType;
  @override
  @JsonKey(name: 'order_note')
  String? get orderNote;
  @override
  @JsonKey(name: 'discount_type')
  String get discountType;
  @override
  @JsonKey(name: 'manual_discount_value')
  int get manualDiscountValue;
  @override
  @JsonKey(name: 'remote_number')
  String? get remoteNumber;
  @override
  @JsonKey(name: 'queue_number')
  int get queueNumber;

  /// Create a copy of PenjualanModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PenjualanModelImplCopyWith<_$PenjualanModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
