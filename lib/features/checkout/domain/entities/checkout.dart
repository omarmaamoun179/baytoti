import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/order_totals.dart';
import '../../../orders/domain/entities/order.dart';

class CheckoutAddress extends Equatable {
  final String id;
  final String label;
  final String line;
  final bool isDefault;

  const CheckoutAddress({
    required this.id,
    required this.label,
    required this.line,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [id, label, line, isDefault];
}

class FulfilmentMethod extends Equatable {
  final String id;
  final String label;
  final String sublabel;
  final int feeFils;
  final bool available;

  const FulfilmentMethod({
    required this.id,
    required this.label,
    required this.sublabel,
    required this.feeFils,
    this.available = true,
  });

  @override
  List<Object?> get props => [id, label, sublabel, feeFils, available];
}

class PaymentMethod extends Equatable {
  final String id;
  final String label;
  final String meta;
  final bool available;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.meta,
    this.available = true,
  });

  @override
  List<Object?> get props => [id, label, meta, available];
}

class CheckoutOptions extends Equatable {
  final List<CheckoutAddress> addresses;
  final List<FulfilmentMethod> fulfilmentMethods;
  final List<PaymentMethod> paymentMethods;

  const CheckoutOptions({
    required this.addresses,
    required this.fulfilmentMethods,
    required this.paymentMethods,
  });

  CheckoutAddress? get defaultAddress =>
      addresses.where((a) => a.isDefault).firstOrNull ?? addresses.firstOrNull;

  FulfilmentMethod? get firstAvailableMethod =>
      fulfilmentMethods.where((m) => m.available).firstOrNull;

  PaymentMethod? get firstAvailablePayment =>
      paymentMethods.where((m) => m.available).firstOrNull;

  CheckoutAddress? address(String? id) =>
      addresses.where((a) => a.id == id).firstOrNull;

  FulfilmentMethod? method(String? id) =>
      fulfilmentMethods.where((m) => m.id == id && m.available).firstOrNull;

  PaymentMethod? payment(String? id) =>
      paymentMethods.where((m) => m.id == id && m.available).firstOrNull;

  @override
  List<Object?> get props => [addresses, fulfilmentMethods, paymentMethods];
}

enum PaymentState {
  succeeded('succeeded'),
  requiresRedirect('requires_redirect');

  final String wire;

  const PaymentState(this.wire);

  static PaymentState? fromWire(Object? value) {
    for (final state in values) {
      if (state.wire == value) return state;
    }
    return null;
  }
}

class PlacedOrder extends Equatable {
  final String orderId;
  final String reference;
  final OrderStatus? status;
  final String totalDisplay;
  final PaymentState? paymentState;
  final String? redirectUrl;
  final String? returnUrl;

  const PlacedOrder({
    required this.orderId,
    required this.reference,
    this.status,
    required this.totalDisplay,
    this.paymentState,
    this.redirectUrl,
    this.returnUrl,
  });

  String? get paymentRedirect =>
      paymentState == PaymentState.requiresRedirect &&
              (redirectUrl?.trim().isNotEmpty ?? false)
          ? redirectUrl
          : null;

  @override
  List<Object?> get props => [
        orderId,
        reference,
        status,
        totalDisplay,
        paymentState,
        redirectUrl,
        returnUrl,
      ];
}

class PlaceOrderParams extends Equatable {
  final String cartId;
  final String addressId;
  final String fulfilmentMethod;
  final String paymentMethod;
  final String? note;
  final String idempotencyKey;

  const PlaceOrderParams({
    required this.cartId,
    required this.addressId,
    required this.fulfilmentMethod,
    required this.paymentMethod,
    this.note,
    required this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
        cartId,
        addressId,
        fulfilmentMethod,
        paymentMethod,
        note,
        idempotencyKey,
      ];
}

extension CheckoutTotals on OrderTotals {
  OrderTotals withShipping(int feeFils, String languageCode) {
    if (feeFils == shipping.fils) return this;
    final totalFils = total.fils + feeFils - shipping.fils;

    return OrderTotals(
      subtotal: subtotal,
      discount: discount,
      shipping: Money(
        fils: feeFils,
        display: Money.format(feeFils, languageCode),
      ),
      total: Money(
        fils: totalFils,
        display: Money.format(totalFils, languageCode),
      ),
    );
  }
}
