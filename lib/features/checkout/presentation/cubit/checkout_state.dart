import 'package:equatable/equatable.dart';

import '../../domain/entities/checkout.dart';

enum CheckoutStatus { initial, loading, loaded, error }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final CheckoutOptions? options;
  final String? addressId;
  final String? fulfilmentId;
  final String? paymentId;
  final bool isPlacing;
  final PlacedOrder? placedOrder;
  final String? errorMessage;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.options,
    this.addressId,
    this.fulfilmentId,
    this.paymentId,
    this.isPlacing = false,
    this.placedOrder,
    this.errorMessage,
  });

  CheckoutAddress? get address => options?.address(addressId);

  FulfilmentMethod? get fulfilment => options?.method(fulfilmentId);

  PaymentMethod? get payment => options?.payment(paymentId);

  bool get isBusy => isPlacing || placedOrder != null;

  bool get canPlace =>
      !isBusy && address != null && fulfilment != null && payment != null;

  CheckoutState copyWith({
    CheckoutStatus? status,
    CheckoutOptions? options,
    String? addressId,
    String? fulfilmentId,
    String? paymentId,
    bool? isPlacing,
    PlacedOrder? placedOrder,
    String? errorMessage,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      options: options ?? this.options,
      addressId: addressId ?? this.addressId,
      fulfilmentId: fulfilmentId ?? this.fulfilmentId,
      paymentId: paymentId ?? this.paymentId,
      isPlacing: isPlacing ?? this.isPlacing,
      placedOrder: placedOrder ?? this.placedOrder,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        options,
        addressId,
        fulfilmentId,
        paymentId,
        isPlacing,
        placedOrder,
        errorMessage,
      ];
}
