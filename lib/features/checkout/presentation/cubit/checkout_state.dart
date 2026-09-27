import 'package:equatable/equatable.dart';

import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/checkout.dart';

enum CheckoutStatus { initial, loading, loaded, error }

class CheckoutState extends Equatable {
  final CheckoutStatus status;
  final List<CheckoutAddress>? addresses;
  final String? addressId;
  final bool isPlacing;
  final List<OrderSummary>? placedOrders;
  final String? errorMessage;

  const CheckoutState({
    this.status = CheckoutStatus.initial,
    this.addresses,
    this.addressId,
    this.isPlacing = false,
    this.placedOrders,
    this.errorMessage,
  });

  CheckoutAddress? get address => addresses?.byId(addressId);

  bool get isBusy => isPlacing || placedOrders != null;

  bool get canPlace => !isBusy && address != null;

  CheckoutState copyWith({
    CheckoutStatus? status,
    List<CheckoutAddress>? addresses,
    String? addressId,
    bool clearAddress = false,
    bool? isPlacing,
    List<OrderSummary>? placedOrders,
    String? errorMessage,
  }) {
    return CheckoutState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      addressId: clearAddress ? null : addressId ?? this.addressId,
      isPlacing: isPlacing ?? this.isPlacing,
      placedOrders: placedOrders ?? this.placedOrders,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        addresses,
        addressId,
        isPlacing,
        placedOrders,
        errorMessage,
      ];
}
