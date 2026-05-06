import 'package:freezed_annotation/freezed_annotation.dart';

part 'pos_payment_model.freezed.dart';
part 'pos_payment_model.g.dart';

@freezed
class PosPaymentModel with _$PosPaymentModel {
  const factory PosPaymentModel({
    int? id,
    @JsonKey(name: 'id_pos') required String idPos,
    @JsonKey(name: 'invoiceid') required String invoiceId,
    required String amount,
    @JsonKey(name: 'paymentmode') required String paymentMode,
    @JsonKey(name: 'paymentmethod') String? paymentMethod,
    required String date,
    @JsonKey(name: 'daterecorded') String? dateRecorded,
    String? note,
    @JsonKey(name: 'transactionid') String? transactionId,
  }) = _PosPaymentModel;

  factory PosPaymentModel.fromJson(Map<String, dynamic> json) =>
      _$PosPaymentModelFromJson(json);
}
