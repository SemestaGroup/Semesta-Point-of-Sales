// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pos_payment_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PosPaymentModel _$PosPaymentModelFromJson(Map<String, dynamic> json) {
  return _PosPaymentModel.fromJson(json);
}

/// @nodoc
mixin _$PosPaymentModel {
  int? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'id_pos')
  String get idPos => throw _privateConstructorUsedError;
  @JsonKey(name: 'invoiceid')
  String get invoiceId => throw _privateConstructorUsedError;
  String get amount => throw _privateConstructorUsedError;
  @JsonKey(name: 'paymentmode')
  String get paymentMode => throw _privateConstructorUsedError;
  @JsonKey(name: 'paymentmethod')
  String? get paymentMethod => throw _privateConstructorUsedError;
  String get date => throw _privateConstructorUsedError;
  @JsonKey(name: 'daterecorded')
  String? get dateRecorded => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'transactionid')
  String? get transactionId => throw _privateConstructorUsedError;

  /// Serializes this PosPaymentModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PosPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PosPaymentModelCopyWith<PosPaymentModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PosPaymentModelCopyWith<$Res> {
  factory $PosPaymentModelCopyWith(
          PosPaymentModel value, $Res Function(PosPaymentModel) then) =
      _$PosPaymentModelCopyWithImpl<$Res, PosPaymentModel>;
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'id_pos') String idPos,
      @JsonKey(name: 'invoiceid') String invoiceId,
      String amount,
      @JsonKey(name: 'paymentmode') String paymentMode,
      @JsonKey(name: 'paymentmethod') String? paymentMethod,
      String date,
      @JsonKey(name: 'daterecorded') String? dateRecorded,
      String? note,
      @JsonKey(name: 'transactionid') String? transactionId});
}

/// @nodoc
class _$PosPaymentModelCopyWithImpl<$Res, $Val extends PosPaymentModel>
    implements $PosPaymentModelCopyWith<$Res> {
  _$PosPaymentModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PosPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? idPos = null,
    Object? invoiceId = null,
    Object? amount = null,
    Object? paymentMode = null,
    Object? paymentMethod = freezed,
    Object? date = null,
    Object? dateRecorded = freezed,
    Object? note = freezed,
    Object? transactionId = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      idPos: null == idPos
          ? _value.idPos
          : idPos // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMode: null == paymentMode
          ? _value.paymentMode
          : paymentMode // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      dateRecorded: freezed == dateRecorded
          ? _value.dateRecorded
          : dateRecorded // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PosPaymentModelImplCopyWith<$Res>
    implements $PosPaymentModelCopyWith<$Res> {
  factory _$$PosPaymentModelImplCopyWith(_$PosPaymentModelImpl value,
          $Res Function(_$PosPaymentModelImpl) then) =
      __$$PosPaymentModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      @JsonKey(name: 'id_pos') String idPos,
      @JsonKey(name: 'invoiceid') String invoiceId,
      String amount,
      @JsonKey(name: 'paymentmode') String paymentMode,
      @JsonKey(name: 'paymentmethod') String? paymentMethod,
      String date,
      @JsonKey(name: 'daterecorded') String? dateRecorded,
      String? note,
      @JsonKey(name: 'transactionid') String? transactionId});
}

/// @nodoc
class __$$PosPaymentModelImplCopyWithImpl<$Res>
    extends _$PosPaymentModelCopyWithImpl<$Res, _$PosPaymentModelImpl>
    implements _$$PosPaymentModelImplCopyWith<$Res> {
  __$$PosPaymentModelImplCopyWithImpl(
      _$PosPaymentModelImpl _value, $Res Function(_$PosPaymentModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PosPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? idPos = null,
    Object? invoiceId = null,
    Object? amount = null,
    Object? paymentMode = null,
    Object? paymentMethod = freezed,
    Object? date = null,
    Object? dateRecorded = freezed,
    Object? note = freezed,
    Object? transactionId = freezed,
  }) {
    return _then(_$PosPaymentModelImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      idPos: null == idPos
          ? _value.idPos
          : idPos // ignore: cast_nullable_to_non_nullable
              as String,
      invoiceId: null == invoiceId
          ? _value.invoiceId
          : invoiceId // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMode: null == paymentMode
          ? _value.paymentMode
          : paymentMode // ignore: cast_nullable_to_non_nullable
              as String,
      paymentMethod: freezed == paymentMethod
          ? _value.paymentMethod
          : paymentMethod // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as String,
      dateRecorded: freezed == dateRecorded
          ? _value.dateRecorded
          : dateRecorded // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      transactionId: freezed == transactionId
          ? _value.transactionId
          : transactionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PosPaymentModelImpl implements _PosPaymentModel {
  const _$PosPaymentModelImpl(
      {this.id,
      @JsonKey(name: 'id_pos') required this.idPos,
      @JsonKey(name: 'invoiceid') required this.invoiceId,
      required this.amount,
      @JsonKey(name: 'paymentmode') required this.paymentMode,
      @JsonKey(name: 'paymentmethod') this.paymentMethod,
      required this.date,
      @JsonKey(name: 'daterecorded') this.dateRecorded,
      this.note,
      @JsonKey(name: 'transactionid') this.transactionId});

  factory _$PosPaymentModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PosPaymentModelImplFromJson(json);

  @override
  final int? id;
  @override
  @JsonKey(name: 'id_pos')
  final String idPos;
  @override
  @JsonKey(name: 'invoiceid')
  final String invoiceId;
  @override
  final String amount;
  @override
  @JsonKey(name: 'paymentmode')
  final String paymentMode;
  @override
  @JsonKey(name: 'paymentmethod')
  final String? paymentMethod;
  @override
  final String date;
  @override
  @JsonKey(name: 'daterecorded')
  final String? dateRecorded;
  @override
  final String? note;
  @override
  @JsonKey(name: 'transactionid')
  final String? transactionId;

  @override
  String toString() {
    return 'PosPaymentModel(id: $id, idPos: $idPos, invoiceId: $invoiceId, amount: $amount, paymentMode: $paymentMode, paymentMethod: $paymentMethod, date: $date, dateRecorded: $dateRecorded, note: $note, transactionId: $transactionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PosPaymentModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.idPos, idPos) || other.idPos == idPos) &&
            (identical(other.invoiceId, invoiceId) ||
                other.invoiceId == invoiceId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.paymentMode, paymentMode) ||
                other.paymentMode == paymentMode) &&
            (identical(other.paymentMethod, paymentMethod) ||
                other.paymentMethod == paymentMethod) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.dateRecorded, dateRecorded) ||
                other.dateRecorded == dateRecorded) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, idPos, invoiceId, amount,
      paymentMode, paymentMethod, date, dateRecorded, note, transactionId);

  /// Create a copy of PosPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PosPaymentModelImplCopyWith<_$PosPaymentModelImpl> get copyWith =>
      __$$PosPaymentModelImplCopyWithImpl<_$PosPaymentModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PosPaymentModelImplToJson(
      this,
    );
  }
}

abstract class _PosPaymentModel implements PosPaymentModel {
  const factory _PosPaymentModel(
          {final int? id,
          @JsonKey(name: 'id_pos') required final String idPos,
          @JsonKey(name: 'invoiceid') required final String invoiceId,
          required final String amount,
          @JsonKey(name: 'paymentmode') required final String paymentMode,
          @JsonKey(name: 'paymentmethod') final String? paymentMethod,
          required final String date,
          @JsonKey(name: 'daterecorded') final String? dateRecorded,
          final String? note,
          @JsonKey(name: 'transactionid') final String? transactionId}) =
      _$PosPaymentModelImpl;

  factory _PosPaymentModel.fromJson(Map<String, dynamic> json) =
      _$PosPaymentModelImpl.fromJson;

  @override
  int? get id;
  @override
  @JsonKey(name: 'id_pos')
  String get idPos;
  @override
  @JsonKey(name: 'invoiceid')
  String get invoiceId;
  @override
  String get amount;
  @override
  @JsonKey(name: 'paymentmode')
  String get paymentMode;
  @override
  @JsonKey(name: 'paymentmethod')
  String? get paymentMethod;
  @override
  String get date;
  @override
  @JsonKey(name: 'daterecorded')
  String? get dateRecorded;
  @override
  String? get note;
  @override
  @JsonKey(name: 'transactionid')
  String? get transactionId;

  /// Create a copy of PosPaymentModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PosPaymentModelImplCopyWith<_$PosPaymentModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
