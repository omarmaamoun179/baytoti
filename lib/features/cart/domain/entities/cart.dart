import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/order_totals.dart';

class CartItem extends Equatable {
  static const int defaultMaxQuantity = 99;

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
    this.family = const FamilyRef(id: '', name: ''),
    this.image,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    this.maxQuantity = defaultMaxQuantity,
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

class Cart extends Equatable {
  final List<CartItem> items;
  final OrderTotals totals;

  const Cart({required this.items, required this.totals});

  bool get isEmpty => items.isEmpty;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartItem? itemFor(String productId) =>
      items.where((item) => item.productId == productId).firstOrNull;

  @override
  List<Object?> get props => [items, totals];
}
