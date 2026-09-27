import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/money.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/order_totals.dart';
import '../../domain/entities/cart.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required super.id,
    required super.productId,
    required super.name,
    super.family,
    super.image,
    required super.unitPrice,
    required super.quantity,
    required super.lineTotal,
    super.maxQuantity,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final product = jsonMap(json['product']);
    final price = jsonMap(json['price']);
    final quantity = jsonCount(json['quantity']) ?? 1;
    final unitPrice = Money.parse(price['unit'] ?? json['unit_price']) ??
        const Money(fils: 0);

    return CartItemModel(
      id: jsonId(json['id']) ?? '',
      productId: jsonId(product['id']) ?? jsonId(json['product_id']) ?? '',
      name: jsonString(product['name']) ?? jsonString(json['name']) ?? '',
      family: FamilyRefModel.fromJson(
        jsonMap(product['store'] ?? json['store']),
      ),
      image: ImageRefModel.maybeFrom(json['image']) ??
          ImageRefModel.maybeFrom(product['thumbnail']),
      unitPrice: unitPrice,
      quantity: quantity,
      lineTotal: Money.parse(price['total'] ?? json['total']) ??
          Money(fils: unitPrice.fils * quantity),
      maxQuantity:
          jsonCount(json['max_quantity']) ?? CartItem.defaultMaxQuantity,
    );
  }
}

class CartModel extends Cart {
  const CartModel({required super.items, required super.totals});

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final items = [
      for (final item in jsonList(json['items'])) CartItemModel.fromJson(item),
    ];

    return CartModel(
      items: items,
      totals: _totals(jsonMap(json['summary']), items),
    );
  }

  static CartModel fromResponse(ApiResponse response) {
    final data = _data(response);
    return data is List
        ? CartModel.fromJson({'items': data})
        : CartModel.fromJson(response.json);
  }

  static bool carriesCart(ApiResponse response) {
    final data = _data(response);
    return data is List || (data is Map && data.containsKey('items'));
  }

  static Object? _data(ApiResponse response) => jsonMap(response.body)['data'];

  static OrderTotals _totals(
    Map<String, dynamic> summary,
    List<CartItem> items,
  ) {
    final subtotal = Money.parse(summary['subtotal']) ??
        Money(fils: items.fold(0, (sum, item) => sum + item.lineTotal.fils));
    final discount = Money.parse(
          summary['discount'] ?? summary['discount_total'],
        ) ??
        const Money(fils: 0);
    final shipping = Money.parse(
          summary['delivery'] ??
              summary['delivery_fee'] ??
              summary['shipping'] ??
              summary['shipping_fee'],
        ) ??
        const Money(fils: 0);

    return OrderTotals(
      subtotal: subtotal,
      discount: discount,
      shipping: shipping,
      total: Money.parse(summary['total'] ?? summary['grand_total']) ??
          Money(fils: subtotal.fils - discount.fils + shipping.fils),
    );
  }
}
