// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment_mode_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaymentModeModel _$PaymentModeModelFromJson(Map<String, dynamic> json) {
  return _PaymentModeModel.fromJson(json);
}

/// @nodoc
mixin _$PaymentModeModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  @JsonKey(name: 'active')
  String get active => throw _privateConstructorUsedError;
  @JsonKey(name: 'selected_by_default')
  String? get selectedByDefault => throw _privateConstructorUsedError;

  /// Serializes this PaymentModeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaymentModeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaymentModeModelCopyWith<PaymentModeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaymentModeModelCopyWith<$Res> {
  factory $PaymentModeModelCopyWith(
          PaymentModeModel value, $Res Function(PaymentModeModel) then) =
      _$PaymentModeModelCopyWithImpl<$Res, PaymentModeModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'active') String active,
      @JsonKey(name: 'selected_by_default') String? selectedByDefault});
}

/// @nodoc
class _$PaymentModeModelCopyWithImpl<$Res, $Val extends PaymentModeModel>
    implements $PaymentModeModelCopyWith<$Res> {
  _$PaymentModeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaymentModeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? active = null,
    Object? selectedByDefault = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as String,
      selectedByDefault: freezed == selectedByDefault
          ? _value.selectedByDefault
          : selectedByDefault // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaymentModeModelImplCopyWith<$Res>
    implements $PaymentModeModelCopyWith<$Res> {
  factory _$$PaymentModeModelImplCopyWith(_$PaymentModeModelImpl value,
          $Res Function(_$PaymentModeModelImpl) then) =
      __$$PaymentModeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String? description,
      @JsonKey(name: 'active') String active,
      @JsonKey(name: 'selected_by_default') String? selectedByDefault});
}

/// @nodoc
class __$$PaymentModeModelImplCopyWithImpl<$Res>
    extends _$PaymentModeModelCopyWithImpl<$Res, _$PaymentModeModelImpl>
    implements _$$PaymentModeModelImplCopyWith<$Res> {
  __$$PaymentModeModelImplCopyWithImpl(_$PaymentModeModelImpl _value,
      $Res Function(_$PaymentModeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaymentModeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = freezed,
    Object? active = null,
    Object? selectedByDefault = freezed,
  }) {
    return _then(_$PaymentModeModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      active: null == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as String,
      selectedByDefault: freezed == selectedByDefault
          ? _value.selectedByDefault
          : selectedByDefault // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaymentModeModelImpl implements _PaymentModeModel {
  const _$PaymentModeModelImpl(
      {required this.id,
      required this.name,
      this.description,
      @JsonKey(name: 'active') required this.active,
      @JsonKey(name: 'selected_by_default') this.selectedByDefault});

  factory _$PaymentModeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaymentModeModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String? description;
  @override
  @JsonKey(name: 'active')
  final String active;
  @override
  @JsonKey(name: 'selected_by_default')
  final String? selectedByDefault;

  @override
  String toString() {
    return 'PaymentModeModel(id: $id, name: $name, description: $description, active: $active, selectedByDefault: $selectedByDefault)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaymentModeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.selectedByDefault, selectedByDefault) ||
                other.selectedByDefault == selectedByDefault));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, name, description, active, selectedByDefault);

  /// Create a copy of PaymentModeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaymentModeModelImplCopyWith<_$PaymentModeModelImpl> get copyWith =>
      __$$PaymentModeModelImplCopyWithImpl<_$PaymentModeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaymentModeModelImplToJson(
      this,
    );
  }
}

abstract class _PaymentModeModel implements PaymentModeModel {
  const factory _PaymentModeModel(
      {required final String id,
      required final String name,
      final String? description,
      @JsonKey(name: 'active') required final String active,
      @JsonKey(name: 'selected_by_default')
      final String? selectedByDefault}) = _$PaymentModeModelImpl;

  factory _PaymentModeModel.fromJson(Map<String, dynamic> json) =
      _$PaymentModeModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String? get description;
  @override
  @JsonKey(name: 'active')
  String get active;
  @override
  @JsonKey(name: 'selected_by_default')
  String? get selectedByDefault;

  /// Create a copy of PaymentModeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaymentModeModelImplCopyWith<_$PaymentModeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
