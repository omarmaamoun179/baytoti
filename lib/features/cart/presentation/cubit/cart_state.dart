import 'package:equatable/equatable.dart';

import '../../domain/entities/cart.dart';

enum CartStatus { initial, loading, loaded, error }

class CartState extends Equatable {
  final CartStatus status;
  final Cart? cart;
  final Set<String> busyItemIds;
  final bool isAdding;
  final bool isApplyingCoupon;
  final String? errorMessage;

  const CartState({
    this.status = CartStatus.initial,
    this.cart,
    this.busyItemIds = const {},
    this.isAdding = false,
    this.isApplyingCoupon = false,
    this.errorMessage,
  });

  int get itemCount => cart?.itemCount ?? 0;

  bool isBusy(String itemId) => busyItemIds.contains(itemId);

  CartState copyWith({
    CartStatus? status,
    Cart? cart,
    Set<String>? busyItemIds,
    bool? isAdding,
    bool? isApplyingCoupon,
    String? errorMessage,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      busyItemIds: busyItemIds ?? this.busyItemIds,
      isAdding: isAdding ?? this.isAdding,
      isApplyingCoupon: isApplyingCoupon ?? this.isApplyingCoupon,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, cart, busyItemIds, isAdding, isApplyingCoupon, errorMessage];
}
