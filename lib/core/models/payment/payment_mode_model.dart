import 'package:freezed_annotation/freezed_annotation.dart';

part 'payment_mode_model.freezed.dart';
part 'payment_mode_model.g.dart';

@freezed
class PaymentModeModel with _$PaymentModeModel {
  const factory PaymentModeModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'active') required String active,
    @JsonKey(name: 'selected_by_default') String? selectedByDefault,
  }) = _PaymentModeModel;

  factory PaymentModeModel.fromJson(Map<String, dynamic> json) =>
      _$PaymentModeModelFromJson(json);
}
