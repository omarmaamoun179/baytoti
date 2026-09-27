import '../../../../core/utils/json.dart';
import '../../../../core/utils/money.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/cart.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.name,
    required super.family,
    super.image,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    required super.maxQuantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) => CartItemModel(
        id: json['id'] as String,
        productId: json['product_id'] as String,
        name: json['name'] as String,
        family: FamilyRefModel.fromJson(jsonMap(json['family'])),
        image: ImageRefModel.maybeFrom(json['image']),
        unitPrice: Money.of(json, 'unit_price'),
        quantity: jsonInt(json['quantity']) ?? 1,
        lineTotal: Money.of(json, 'line_total'),
        maxQuantity: jsonInt(json['max_quantity']) ?? 99,
      );
}

class CartModel extends Cart {
  const CartModel({
    required super.id,
    required super.items,
    super.coupon,
    required super.totals,
    required super.itemCount,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final coupon = jsonMapOrNull(json['coupon']);
    final items = [
      for (final item in jsonList(json['items'])) CartItemModel.fromJson(item),
    ];

    return CartModel(
      id: json['id'] as String,
      items: items,
      coupon: coupon == null
          ? null
          : CartCoupon(
              code: coupon['code'] as String,
              discountFils: jsonInt(coupon['discount_fils']) ?? 0,
            ),
      totals: OrderTotalsModel.fromJson(jsonMap(json['totals'])),
      itemCount: jsonInt(json['item_count']) ?? items.length,
    );
  }
}
