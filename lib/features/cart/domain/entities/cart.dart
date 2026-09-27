import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/order_totals.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String name;
  final FamilyRef family;
  final ImageRef? image;
  final Money unitPrice;
  final int quantity;
  final Money lineTotal;
  final int maxQuantity;

  const CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.family,
    this.image,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.maxQuantity,
  });

  bool get canIncrement => quantity < maxQuantity;

  bool get canDecrement => quantity > 1;

  @override
  List<Object?> get props => [
        id,
        productId,
        name,
        family,
        image,
        unitPrice,
        quantity,
        lineTotal,
        maxQuantity,
      ];
}

class CartCoupon extends Equatable {
  final String code;
  final int discountFils;

  const CartCoupon({required this.code, required this.discountFils});

  @override
  List<Object?> get props => [code, discountFils];
}

class Cart extends Equatable {
  final String id;
  final List<CartItem> items;
  final CartCoupon? coupon;
  final OrderTotals totals;
  final int itemCount;

  const Cart({
    required this.id,
    required this.items,
    this.coupon,
    required this.totals,
    required this.itemCount,
  });

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [id, items, coupon, totals, itemCount];
}
