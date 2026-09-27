import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/order_totals.dart';

enum OrderStatus {
  placed('placed'),
  accepted('accepted'),
  preparing('preparing'),
  ready('ready'),
  outForDelivery('out_for_delivery'),
  delivered('delivered'),
  cancelled('cancelled'),
  rejected('rejected');

  final String wire;

  const OrderStatus(this.wire);

  static OrderStatus? fromWire(Object? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

class OrderSummary extends Equatable {
  final String id;
  final String reference;
  final OrderStatus? status;
  final String totalDisplay;

  const OrderSummary({
    required this.id,
    required this.reference,
    this.status,
    required this.totalDisplay,
  });

  @override
  List<Object?> get props => [id, reference, status, totalDisplay];
}

class OrderTimelineStep extends Equatable {
  final OrderStatus? status;
  final String label;
  final DateTime? at;
  final String? atDisplay;
  final bool done;

  const OrderTimelineStep({
    this.status,
    required this.label,
    this.at,
    this.atDisplay,
    required this.done,
  });

  @override
  List<Object?> get props => [status, label, at, atDisplay, done];
}

class OrderLine extends Equatable {
  final String productId;
  final String name;
  final int quantity;
  final String lineTotalDisplay;
  final ImageRef? image;

  const OrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.lineTotalDisplay,
    this.image,
  });

  @override
  List<Object?> get props =>
      [productId, name, quantity, lineTotalDisplay, image];
}

class OrderDetail extends Equatable {
  final String id;
  final String reference;
  final OrderStatus? status;
  final String? etaDisplay;
  final List<OrderTimelineStep> timeline;
  final List<OrderLine> items;
  final OrderTotals totals;
  final FamilyRef? family;
  final bool canRate;
  final bool canCancel;

  const OrderDetail({
    required this.id,
    required this.reference,
    this.status,
    this.etaDisplay,
    required this.timeline,
    required this.items,
    required this.totals,
    this.family,
    this.canRate = false,
    this.canCancel = false,
  });

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        etaDisplay,
        timeline,
        items,
        totals,
        family,
        canRate,
        canCancel,
      ];
}

class OrdersQuery extends Equatable {
  final OrderStatus? status;
  final String? cursor;

  const OrdersQuery({this.status, this.cursor});

  Map<String, dynamic> toQueryParameters() => {
        'status': ?status?.wire,
        'cursor': ?cursor,
      };

  @override
  List<Object?> get props => [status, cursor];
}

class RateOrderParams extends Equatable {
  static const int minRating = 1;
  static const int maxRating = 5;

  final String orderId;
  final int rating;

  const RateOrderParams({required this.orderId, required this.rating});

  @override
  List<Object?> get props => [orderId, rating];
}
