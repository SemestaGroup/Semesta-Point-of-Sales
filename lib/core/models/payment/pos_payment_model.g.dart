// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_payment_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PosPaymentModelImpl _$$PosPaymentModelImplFromJson(
        Map<String, dynamic> json) =>
    _$PosPaymentModelImpl(
      id: (json['id'] as num?)?.toInt(),
      idPos: json['id_pos'] as String,
      invoiceId: json['invoiceid'] as String,
      amount: json['amount'] as String,
      paymentMode: json['paymentmode'] as String,
      paymentMethod: json['paymentmethod'] as String?,
      date: json['date'] as String,
      dateRecorded: json['daterecorded'] as String?,
      note: json['note'] as String?,
      transactionId: json['transactionid'] as String?,
    );

Map<String, dynamic> _$$PosPaymentModelImplToJson(
        _$PosPaymentModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'id_pos': instance.idPos,
      'invoiceid': instance.invoiceId,
      'amount': instance.amount,
      'paymentmode': instance.paymentMode,
      'paymentmethod': instance.paymentMethod,
      'date': instance.date,
      'daterecorded': instance.dateRecorded,
      'note': instance.note,
      'transactionid': instance.transactionId,
    };
