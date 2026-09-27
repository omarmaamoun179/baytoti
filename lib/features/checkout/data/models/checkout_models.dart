import '../../../../core/utils/json.dart';
import '../../../orders/domain/entities/order.dart';
import '../../domain/entities/checkout.dart';

class CheckoutAddressModel extends CheckoutAddress {
  const CheckoutAddressModel({
    required super.id,
    required super.label,
    required super.line,
    super.isDefault,
  });

  factory CheckoutAddressModel.fromJson(Map<String, dynamic> json) =>
      CheckoutAddressModel(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        line: json['line'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
      );
}

class FulfilmentMethodModel extends FulfilmentMethod {
  const FulfilmentMethodModel({
    required super.id,
    required super.label,
    required super.sublabel,
    required super.feeFils,
    super.available,
  });

  factory FulfilmentMethodModel.fromJson(Map<String, dynamic> json) =>
      FulfilmentMethodModel(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        sublabel: json['sublabel'] as String? ?? '',
        feeFils: jsonInt(json['fee_fils']) ?? 0,
        available: json['available'] as bool? ?? true,
      );
}

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.label,
    required super.meta,
    super.available,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) =>
      PaymentMethodModel(
        id: json['id'] as String,
        label: json['label'] as String? ?? '',
        meta: json['meta'] as String? ?? '',
        available: json['available'] as bool? ?? true,
      );
}

class CheckoutOptionsModel extends CheckoutOptions {
  const CheckoutOptionsModel({
    required super.addresses,
    required super.fulfilmentMethods,
    required super.paymentMethods,
  });

  factory CheckoutOptionsModel.fromJson(Map<String, dynamic> json) =>
      CheckoutOptionsModel(
        addresses: [
          for (final address in jsonList(json['addresses']))
            CheckoutAddressModel.fromJson(address),
        ],
        fulfilmentMethods: [
          for (final method in jsonList(json['fulfilment_methods']))
            FulfilmentMethodModel.fromJson(method),
        ],
        paymentMethods: [
          for (final method in jsonList(json['payment_methods']))
            PaymentMethodModel.fromJson(method),
        ],
      );
}

class PlacedOrderModel extends PlacedOrder {
  const PlacedOrderModel({
    required super.orderId,
    required super.reference,
    super.status,
    required super.totalDisplay,
    super.paymentState,
    super.redirectUrl,
    super.returnUrl,
  });

  factory PlacedOrderModel.fromJson(Map<String, dynamic> json) {
    final order = jsonMap(json['order']);
    final payment = jsonMap(json['payment']);

    return PlacedOrderModel(
      orderId: order['id'] as String,
      reference: order['reference'] as String? ?? '',
      status: OrderStatus.fromWire(order['status']),
      totalDisplay: order['total_display'] as String? ?? '',
      paymentState: PaymentState.fromWire(payment['state']),
      redirectUrl: payment['redirect_url'] as String?,
      returnUrl: payment['return_url'] as String?,
    );
  }
}

extension PlaceOrderRequest on PlaceOrderParams {
  Map<String, dynamic> toJson() => {
        'cart_id': cartId,
        'address_id': addressId,
        'fulfilment_method': fulfilmentMethod,
        'payment_method': paymentMethod,
        'note': note,
        'idempotency_key': idempotencyKey,
      };
}
