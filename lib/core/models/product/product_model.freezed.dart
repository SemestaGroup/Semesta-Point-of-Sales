// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) {
  return _ProductModel.fromJson(json);
}

/// @nodoc
mixin _$ProductModel {
  @JsonKey(name: 'id', fromJson: _toInt)
  int get idProduk => throw _privateConstructorUsedError;
  @JsonKey(name: 'category_id', fromJson: _toInt)
  int get idKategori => throw _privateConstructorUsedError;
  @JsonKey(name: 'sku')
  String? get kodeProduk => throw _privateConstructorUsedError;
  @JsonKey(name: 'name')
  String? get namaProduk => throw _privateConstructorUsedError;
  String? get merk => throw _privateConstructorUsedError;
  @JsonKey(name: 'cost', fromJson: _toInt)
  int get hargaBeli => throw _privateConstructorUsedError;
  int get diskon => throw _privateConstructorUsedError;
  @JsonKey(name: 'price', fromJson: _toInt)
  int get hargaJual => throw _privateConstructorUsedError;
  @JsonKey(name: 'stock_quantity', fromJson: _toInt)
  int get stok => throw _privateConstructorUsedError;
  @JsonKey(name: 'image_url')
  String? get img => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  String? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  String? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'nama_kategori')
  String? get namaKategori => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_types')
  String? get orderTypes => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_total', fromJson: _toInt)
  int get discountTotal => throw _privateConstructorUsedError;
  @JsonKey(name: 'discount_type')
  String get discountType => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'parent')
  String? get parent => throw _privateConstructorUsedError;
  @JsonKey(name: 'children')
  String? get children => throw _privateConstructorUsedError;

  /// Serializes this ProductModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProductModelCopyWith<ProductModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProductModelCopyWith<$Res> {
  factory $ProductModelCopyWith(
          ProductModel value, $Res Function(ProductModel) then) =
      _$ProductModelCopyWithImpl<$Res, ProductModel>;
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _toInt) int idProduk,
      @JsonKey(name: 'category_id', fromJson: _toInt) int idKategori,
      @JsonKey(name: 'sku') String? kodeProduk,
      @JsonKey(name: 'name') String? namaProduk,
      String? merk,
      @JsonKey(name: 'cost', fromJson: _toInt) int hargaBeli,
      int diskon,
      @JsonKey(name: 'price', fromJson: _toInt) int hargaJual,
      @JsonKey(name: 'stock_quantity', fromJson: _toInt) int stok,
      @JsonKey(name: 'image_url') String? img,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      @JsonKey(name: 'nama_kategori') String? namaKategori,
      @JsonKey(name: 'order_types') String? orderTypes,
      @JsonKey(name: 'discount_total', fromJson: _toInt) int discountTotal,
      @JsonKey(name: 'discount_type') String discountType,
      String status,
      @JsonKey(name: 'parent') String? parent,
      @JsonKey(name: 'children') String? children});
}

/// @nodoc
class _$ProductModelCopyWithImpl<$Res, $Val extends ProductModel>
    implements $ProductModelCopyWith<$Res> {
  _$ProductModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idProduk = null,
    Object? idKategori = null,
    Object? kodeProduk = freezed,
    Object? namaProduk = freezed,
    Object? merk = freezed,
    Object? hargaBeli = null,
    Object? diskon = null,
    Object? hargaJual = null,
    Object? stok = null,
    Object? img = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? namaKategori = freezed,
    Object? orderTypes = freezed,
    Object? discountTotal = null,
    Object? discountType = null,
    Object? status = null,
    Object? parent = freezed,
    Object? children = freezed,
  }) {
    return _then(_value.copyWith(
      idProduk: null == idProduk
          ? _value.idProduk
          : idProduk // ignore: cast_nullable_to_non_nullable
              as int,
      idKategori: null == idKategori
          ? _value.idKategori
          : idKategori // ignore: cast_nullable_to_non_nullable
              as int,
      kodeProduk: freezed == kodeProduk
          ? _value.kodeProduk
          : kodeProduk // ignore: cast_nullable_to_non_nullable
              as String?,
      namaProduk: freezed == namaProduk
          ? _value.namaProduk
          : namaProduk // ignore: cast_nullable_to_non_nullable
              as String?,
      merk: freezed == merk
          ? _value.merk
          : merk // ignore: cast_nullable_to_non_nullable
              as String?,
      hargaBeli: null == hargaBeli
          ? _value.hargaBeli
          : hargaBeli // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      hargaJual: null == hargaJual
          ? _value.hargaJual
          : hargaJual // ignore: cast_nullable_to_non_nullable
              as int,
      stok: null == stok
          ? _value.stok
          : stok // ignore: cast_nullable_to_non_nullable
              as int,
      img: freezed == img
          ? _value.img
          : img // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      namaKategori: freezed == namaKategori
          ? _value.namaKategori
          : namaKategori // ignore: cast_nullable_to_non_nullable
              as String?,
      orderTypes: freezed == orderTypes
          ? _value.orderTypes
          : orderTypes // ignore: cast_nullable_to_non_nullable
              as String?,
      discountTotal: null == discountTotal
          ? _value.discountTotal
          : discountTotal // ignore: cast_nullable_to_non_nullable
              as int,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String?,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProductModelImplCopyWith<$Res>
    implements $ProductModelCopyWith<$Res> {
  factory _$$ProductModelImplCopyWith(
          _$ProductModelImpl value, $Res Function(_$ProductModelImpl) then) =
      __$$ProductModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'id', fromJson: _toInt) int idProduk,
      @JsonKey(name: 'category_id', fromJson: _toInt) int idKategori,
      @JsonKey(name: 'sku') String? kodeProduk,
      @JsonKey(name: 'name') String? namaProduk,
      String? merk,
      @JsonKey(name: 'cost', fromJson: _toInt) int hargaBeli,
      int diskon,
      @JsonKey(name: 'price', fromJson: _toInt) int hargaJual,
      @JsonKey(name: 'stock_quantity', fromJson: _toInt) int stok,
      @JsonKey(name: 'image_url') String? img,
      @JsonKey(name: 'created_at') String? createdAt,
      @JsonKey(name: 'updated_at') String? updatedAt,
      @JsonKey(name: 'nama_kategori') String? namaKategori,
      @JsonKey(name: 'order_types') String? orderTypes,
      @JsonKey(name: 'discount_total', fromJson: _toInt) int discountTotal,
      @JsonKey(name: 'discount_type') String discountType,
      String status,
      @JsonKey(name: 'parent') String? parent,
      @JsonKey(name: 'children') String? children});
}

/// @nodoc
class __$$ProductModelImplCopyWithImpl<$Res>
    extends _$ProductModelCopyWithImpl<$Res, _$ProductModelImpl>
    implements _$$ProductModelImplCopyWith<$Res> {
  __$$ProductModelImplCopyWithImpl(
      _$ProductModelImpl _value, $Res Function(_$ProductModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? idProduk = null,
    Object? idKategori = null,
    Object? kodeProduk = freezed,
    Object? namaProduk = freezed,
    Object? merk = freezed,
    Object? hargaBeli = null,
    Object? diskon = null,
    Object? hargaJual = null,
    Object? stok = null,
    Object? img = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? namaKategori = freezed,
    Object? orderTypes = freezed,
    Object? discountTotal = null,
    Object? discountType = null,
    Object? status = null,
    Object? parent = freezed,
    Object? children = freezed,
  }) {
    return _then(_$ProductModelImpl(
      idProduk: null == idProduk
          ? _value.idProduk
          : idProduk // ignore: cast_nullable_to_non_nullable
              as int,
      idKategori: null == idKategori
          ? _value.idKategori
          : idKategori // ignore: cast_nullable_to_non_nullable
              as int,
      kodeProduk: freezed == kodeProduk
          ? _value.kodeProduk
          : kodeProduk // ignore: cast_nullable_to_non_nullable
              as String?,
      namaProduk: freezed == namaProduk
          ? _value.namaProduk
          : namaProduk // ignore: cast_nullable_to_non_nullable
              as String?,
      merk: freezed == merk
          ? _value.merk
          : merk // ignore: cast_nullable_to_non_nullable
              as String?,
      hargaBeli: null == hargaBeli
          ? _value.hargaBeli
          : hargaBeli // ignore: cast_nullable_to_non_nullable
              as int,
      diskon: null == diskon
          ? _value.diskon
          : diskon // ignore: cast_nullable_to_non_nullable
              as int,
      hargaJual: null == hargaJual
          ? _value.hargaJual
          : hargaJual // ignore: cast_nullable_to_non_nullable
              as int,
      stok: null == stok
          ? _value.stok
          : stok // ignore: cast_nullable_to_non_nullable
              as int,
      img: freezed == img
          ? _value.img
          : img // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as String?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      namaKategori: freezed == namaKategori
          ? _value.namaKategori
          : namaKategori // ignore: cast_nullable_to_non_nullable
              as String?,
      orderTypes: freezed == orderTypes
          ? _value.orderTypes
          : orderTypes // ignore: cast_nullable_to_non_nullable
              as String?,
      discountTotal: null == discountTotal
          ? _value.discountTotal
          : discountTotal // ignore: cast_nullable_to_non_nullable
              as int,
      discountType: null == discountType
          ? _value.discountType
          : discountType // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      parent: freezed == parent
          ? _value.parent
          : parent // ignore: cast_nullable_to_non_nullable
              as String?,
      children: freezed == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProductModelImpl implements _ProductModel {
  const _$ProductModelImpl(
      {@JsonKey(name: 'id', fromJson: _toInt) this.idProduk = 0,
      @JsonKey(name: 'category_id', fromJson: _toInt) this.idKategori = 0,
      @JsonKey(name: 'sku') this.kodeProduk,
      @JsonKey(name: 'name') this.namaProduk,
      this.merk,
      @JsonKey(name: 'cost', fromJson: _toInt) this.hargaBeli = 0,
      this.diskon = 0,
      @JsonKey(name: 'price', fromJson: _toInt) this.hargaJual = 0,
      @JsonKey(name: 'stock_quantity', fromJson: _toInt) this.stok = 0,
      @JsonKey(name: 'image_url') this.img,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt,
      @JsonKey(name: 'nama_kategori') this.namaKategori,
      @JsonKey(name: 'order_types') this.orderTypes,
      @JsonKey(name: 'discount_total', fromJson: _toInt) this.discountTotal = 0,
      @JsonKey(name: 'discount_type') this.discountType = 'percent',
      this.status = 'active',
      @JsonKey(name: 'parent') this.parent,
      @JsonKey(name: 'children') this.children});

  factory _$ProductModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProductModelImplFromJson(json);

  @override
  @JsonKey(name: 'id', fromJson: _toInt)
  final int idProduk;
  @override
  @JsonKey(name: 'category_id', fromJson: _toInt)
  final int idKategori;
  @override
  @JsonKey(name: 'sku')
  final String? kodeProduk;
  @override
  @JsonKey(name: 'name')
  final String? namaProduk;
  @override
  final String? merk;
  @override
  @JsonKey(name: 'cost', fromJson: _toInt)
  final int hargaBeli;
  @override
  @JsonKey()
  final int diskon;
  @override
  @JsonKey(name: 'price', fromJson: _toInt)
  final int hargaJual;
  @override
  @JsonKey(name: 'stock_quantity', fromJson: _toInt)
  final int stok;
  @override
  @JsonKey(name: 'image_url')
  final String? img;
  @override
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @override
  @JsonKey(name: 'nama_kategori')
  final String? namaKategori;
  @override
  @JsonKey(name: 'order_types')
  final String? orderTypes;
  @override
  @JsonKey(name: 'discount_total', fromJson: _toInt)
  final int discountTotal;
  @override
  @JsonKey(name: 'discount_type')
  final String discountType;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'parent')
  final String? parent;
  @override
  @JsonKey(name: 'children')
  final String? children;

  @override
  String toString() {
    return 'ProductModel(idProduk: $idProduk, idKategori: $idKategori, kodeProduk: $kodeProduk, namaProduk: $namaProduk, merk: $merk, hargaBeli: $hargaBeli, diskon: $diskon, hargaJual: $hargaJual, stok: $stok, img: $img, createdAt: $createdAt, updatedAt: $updatedAt, namaKategori: $namaKategori, orderTypes: $orderTypes, discountTotal: $discountTotal, discountType: $discountType, status: $status, parent: $parent, children: $children)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProductModelImpl &&
            (identical(other.idProduk, idProduk) ||
                other.idProduk == idProduk) &&
            (identical(other.idKategori, idKategori) ||
                other.idKategori == idKategori) &&
            (identical(other.kodeProduk, kodeProduk) ||
                other.kodeProduk == kodeProduk) &&
            (identical(other.namaProduk, namaProduk) ||
                other.namaProduk == namaProduk) &&
            (identical(other.merk, merk) || other.merk == merk) &&
            (identical(other.hargaBeli, hargaBeli) ||
                other.hargaBeli == hargaBeli) &&
            (identical(other.diskon, diskon) || other.diskon == diskon) &&
            (identical(other.hargaJual, hargaJual) ||
                other.hargaJual == hargaJual) &&
            (identical(other.stok, stok) || other.stok == stok) &&
            (identical(other.img, img) || other.img == img) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.namaKategori, namaKategori) ||
                other.namaKategori == namaKategori) &&
            (identical(other.orderTypes, orderTypes) ||
                other.orderTypes == orderTypes) &&
            (identical(other.discountTotal, discountTotal) ||
                other.discountTotal == discountTotal) &&
            (identical(other.discountType, discountType) ||
                other.discountType == discountType) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.parent, parent) || other.parent == parent) &&
            (identical(other.children, children) ||
                other.children == children));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        idProduk,
        idKategori,
        kodeProduk,
        namaProduk,
        merk,
        hargaBeli,
        diskon,
        hargaJual,
        stok,
        img,
        createdAt,
        updatedAt,
        namaKategori,
        orderTypes,
        discountTotal,
        discountType,
        status,
        parent,
        children
      ]);

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProductModelImplCopyWith<_$ProductModelImpl> get copyWith =>
      __$$ProductModelImplCopyWithImpl<_$ProductModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProductModelImplToJson(
      this,
    );
  }
}

abstract class _ProductModel implements ProductModel {
  const factory _ProductModel(
      {@JsonKey(name: 'id', fromJson: _toInt) final int idProduk,
      @JsonKey(name: 'category_id', fromJson: _toInt) final int idKategori,
      @JsonKey(name: 'sku') final String? kodeProduk,
      @JsonKey(name: 'name') final String? namaProduk,
      final String? merk,
      @JsonKey(name: 'cost', fromJson: _toInt) final int hargaBeli,
      final int diskon,
      @JsonKey(name: 'price', fromJson: _toInt) final int hargaJual,
      @JsonKey(name: 'stock_quantity', fromJson: _toInt) final int stok,
      @JsonKey(name: 'image_url') final String? img,
      @JsonKey(name: 'created_at') final String? createdAt,
      @JsonKey(name: 'updated_at') final String? updatedAt,
      @JsonKey(name: 'nama_kategori') final String? namaKategori,
      @JsonKey(name: 'order_types') final String? orderTypes,
      @JsonKey(name: 'discount_total', fromJson: _toInt)
      final int discountTotal,
      @JsonKey(name: 'discount_type') final String discountType,
      final String status,
      @JsonKey(name: 'parent') final String? parent,
      @JsonKey(name: 'children') final String? children}) = _$ProductModelImpl;

  factory _ProductModel.fromJson(Map<String, dynamic> json) =
      _$ProductModelImpl.fromJson;

  @override
  @JsonKey(name: 'id', fromJson: _toInt)
  int get idProduk;
  @override
  @JsonKey(name: 'category_id', fromJson: _toInt)
  int get idKategori;
  @override
  @JsonKey(name: 'sku')
  String? get kodeProduk;
  @override
  @JsonKey(name: 'name')
  String? get namaProduk;
  @override
  String? get merk;
  @override
  @JsonKey(name: 'cost', fromJson: _toInt)
  int get hargaBeli;
  @override
  int get diskon;
  @override
  @JsonKey(name: 'price', fromJson: _toInt)
  int get hargaJual;
  @override
  @JsonKey(name: 'stock_quantity', fromJson: _toInt)
  int get stok;
  @override
  @JsonKey(name: 'image_url')
  String? get img;
  @override
  @JsonKey(name: 'created_at')
  String? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  String? get updatedAt;
  @override
  @JsonKey(name: 'nama_kategori')
  String? get namaKategori;
  @override
  @JsonKey(name: 'order_types')
  String? get orderTypes;
  @override
  @JsonKey(name: 'discount_total', fromJson: _toInt)
  int get discountTotal;
  @override
  @JsonKey(name: 'discount_type')
  String get discountType;
  @override
  String get status;
  @override
  @JsonKey(name: 'parent')
  String? get parent;
  @override
  @JsonKey(name: 'children')
  String? get children;

  /// Create a copy of ProductModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProductModelImplCopyWith<_$ProductModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
