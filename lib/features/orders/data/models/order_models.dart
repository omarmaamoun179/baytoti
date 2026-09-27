import '../../../../core/domain/paged.dart';
import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/order.dart';

class OrderSummaryModel extends OrderSummary {
  const OrderSummaryModel({
    required super.id,
    required super.reference,
    super.status,
    required super.totalDisplay,
  });

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) =>
      OrderSummaryModel(
        id: json['id'] as String,
        reference: json['reference'] as String? ?? '',
        status: OrderStatus.fromWire(json['status']),
        totalDisplay: json['total_display'] as String? ?? '',
      );

  static Paged<OrderSummary> pageFrom(Map<String, dynamic> json) =>
      Paged<OrderSummary>(
        items: [
          for (final item in jsonList(json['items']))
            OrderSummaryModel.fromJson(item),
        ],
        nextCursor: json['next_cursor'] as String?,
        total: jsonInt(json['total']),
      );
}

class OrderTimelineStepModel extends OrderTimelineStep {
  const OrderTimelineStepModel({
    super.status,
    required super.label,
    super.at,
    super.atDisplay,
    required super.done,
  });

  factory OrderTimelineStepModel.fromJson(Map<String, dynamic> json) =>
      OrderTimelineStepModel(
        status: OrderStatus.fromWire(json['status']),
        label: json['label'] as String? ?? '',
        at: switch (json['at']) {
          final String value => DateTime.tryParse(value),
          _ => null,
        },
        atDisplay: json['at_display'] as String?,
        done: json['done'] as bool? ?? false,
      );
}

class OrderLineModel extends OrderLine {
  const OrderLineModel({
    required super.productId,
    required super.name,
    required super.quantity,
    required super.lineTotalDisplay,
    super.image,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) => OrderLineModel(
        productId: json['product_id'] as String,
        name: json['name'] as String,
        quantity: jsonInt(json['quantity']) ?? 1,
        lineTotalDisplay: json['line_total_display'] as String? ?? '',
        image: ImageRefModel.maybeFrom(json['image']),
      );
}

class OrderDetailModel extends OrderDetail {
  const OrderDetailModel({
    required super.id,
    required super.reference,
    super.status,
    super.etaDisplay,
    required super.timeline,
    required super.items,
    required super.totals,
    super.family,
    super.canRate,
    super.canCancel,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    final family = jsonMapOrNull(json['family']);

    return OrderDetailModel(
      id: json['id'] as String,
      reference: json['reference'] as String? ?? '',
      status: OrderStatus.fromWire(json['status']),
      etaDisplay: json['eta_display'] as String?,
      timeline: [
        for (final step in jsonList(json['timeline']))
          OrderTimelineStepModel.fromJson(step),
      ],
      items: [
        for (final item in jsonList(json['items']))
          OrderLineModel.fromJson(item),
      ],
      totals: OrderTotalsModel.fromJson(jsonMap(json['totals'])),
      family: family == null ? null : FamilyRefModel.fromJson(family),
      canRate: json['can_rate'] as bool? ?? false,
      canCancel: json['can_cancel'] as bool? ?? false,
    );
  }
}
