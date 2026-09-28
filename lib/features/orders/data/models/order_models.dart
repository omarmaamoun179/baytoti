import '../../../../core/domain/paged.dart';
import '../../../../core/exceptions/app_exceptions.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/json.dart';
import '../../../../core/utils/money.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/order_totals.dart';
import '../../domain/entities/order.dart';

OrderTotals _totalsFrom(Map<String, dynamic> json) {
  final financials = jsonMap(json['financials']);
  final subtotal =
      Money.parse(financials['subtotal']) ?? const Money(fils: 0);
  final discount =
      Money.parse(financials['discount']) ?? const Money(fils: 0);
  final shipping = Money.parse(
        financials['shipping_fee'] ??
            financials['shipping'] ??
            financials['delivery_fee'],
      ) ??
      const Money(fils: 0);

  return OrderTotals(
    subtotal: subtotal,
    discount: discount,
    shipping: shipping,
    total: Money.parse(financials['total']) ??
        Money(fils: subtotal.fils - discount.fils + shipping.fils),
  );
}

FamilyRef? _familyFrom(Map<String, dynamic> json) {
  final store = jsonMapOrNull(json['store']);
  return store == null ? null : FamilyRefModel.fromJson(store);
}

DateTime? _dateFrom(Object? value) =>
    DateTime.tryParse(jsonString(value) ?? '')?.toLocal();

String _referenceFrom(Map<String, dynamic> json) =>
    jsonString(json['order_number'] ?? json['reference']) ?? '';

class OrderSummaryModel extends OrderSummary {
  const OrderSummaryModel({
    required super.id,
    required super.reference,
    super.status,
    required super.total,
    super.family,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) =>
      OrderSummaryModel(
        id: jsonId(json['id']) ?? '',
        reference: _referenceFrom(json),
        status: OrderStatus.fromWire(json['status']),
        total: _totalsFrom(json).total,
        family: _familyFrom(json),
      );

  static List<OrderSummary> listFrom(Object? value) => [
        for (final item in jsonList(value)) OrderSummaryModel.fromJson(item),
      ].where((order) => order.id.isNotEmpty).toList();

  static Paged<OrderSummary> pageFrom(Map<String, dynamic> json) {
    final page = Paged.fromJson(json, OrderSummaryModel.fromJson);
    return Paged<OrderSummary>(
      items: page.items.where((order) => order.id.isNotEmpty).toList(),
      currentPage: page.currentPage,
      lastPage: page.lastPage,
      total: page.total,
    );
  }

  static List<OrderSummary> listFromCheckout(ApiResponse response) {
    final data = jsonMap(response.body)['data'];
    if (data is List) return listFrom(data);

    final map = jsonMap(data);
    final orders = map['orders'];
    if (orders is List) return listFrom(orders);

    final order = jsonMapOrNull(map['order']) ?? map;
    return order.containsKey('order_number') ? listFrom([order]) : const [];
  }
}

class OrderLineModel extends OrderLine {
  const OrderLineModel({
    required super.id,
    super.productId,
    required super.name,
    required super.quantity,
    required super.unitPrice,
    required super.lineTotal,
    super.image,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    final quantity = jsonCount(json['quantity']) ?? 1;
    final unitPrice =
        Money.parse(json['unit_price']) ?? const Money(fils: 0);

    return OrderLineModel(
      id: jsonId(json['id']) ?? '',
      productId: jsonId(json['product_id']),
      name: jsonString(json['product_name'] ?? json['name']) ?? '',
      quantity: quantity,
      unitPrice: unitPrice,
      lineTotal: Money.parse(json['total']) ??
          Money(fils: unitPrice.fils * quantity),
      image: ImageRefModel.maybeFrom(json['image']),
    );
  }
}

class OrderDetailModel extends OrderDetail {
  const OrderDetailModel({
    required super.id,
    required super.reference,
    super.status,
    required super.items,
    required super.totals,
    super.family,
    super.notes,
    super.createdAt,
    super.updatedAt,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      OrderDetailModel(
        id: jsonId(json['id']) ?? '',
        reference: _referenceFrom(json),
        status: OrderStatus.fromWire(json['status']),
        items: [
          for (final item in jsonList(json['items']))
            OrderLineModel.fromJson(item),
        ],
        totals: _totalsFrom(json),
        family: _familyFrom(json),
        notes: jsonString(json['notes']),
        createdAt: _dateFrom(json['created_at']),
        updatedAt: _dateFrom(json['updated_at']),
      );

  static OrderDetailModel fromResponse(ApiResponse response) {
    final order = OrderDetailModel.fromJson(_orderMap(response));
    if (order.id.isEmpty) {
      throw const RequestException('order_not_found', statusCode: 404);
    }
    return order;
  }

  static bool carriesOrder(ApiResponse response) =>
      _orderMap(response).containsKey('order_number');

  static Map<String, dynamic> _orderMap(ApiResponse response) {
    final data = response.json;
    return jsonMapOrNull(data['order']) ?? data;
  }
}
