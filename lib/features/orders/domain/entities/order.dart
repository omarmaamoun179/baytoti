import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../catalog/domain/entities/order_totals.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled;

  static const List<OrderStatus> flow = [
    pending,
    confirmed,
    processing,
    shipped,
    delivered,
  ];

  static const List<OrderStatus> cancelledFlow = [pending, cancelled];

  String get wire => name;

  bool get isCancellable => this == pending || this == confirmed;

  static OrderStatus? fromWire(Object? value) {
    final wire = value is String ? value.trim().toLowerCase() : null;
    return values.where((status) => status.name == wire).firstOrNull;
  }
}

class OrderSummary extends Equatable {
  final String id;
  final String reference;
  final OrderStatus? status;
  final Money total;
  final FamilyRef? family;

  const OrderSummary({
    required this.id,
    required this.reference,
    this.status,
    required this.total,
    this.family,
  });

  @override
  List<Object?> get props => [id, reference, status, total, family];
}

class OrderTimelineStep extends Equatable {
  final OrderStatus status;
  final DateTime? at;
  final bool done;

  const OrderTimelineStep({required this.status, this.at, required this.done});

  @override
  List<Object?> get props => [status, at, done];
}

class OrderLine extends Equatable {
  final String id;
  final String? productId;
  final String name;
  final int quantity;
  final Money unitPrice;
  final Money lineTotal;
  final ImageRef? image;

  const OrderLine({
    required this.id,
    this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.image,
  });

  @override
  List<Object?> get props =>
      [id, productId, name, quantity, unitPrice, lineTotal, image];
}

class OrderDetail extends Equatable {
  final String id;
  final String reference;
  final OrderStatus? status;
  final List<OrderLine> items;
  final OrderTotals totals;
  final FamilyRef? family;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrderDetail({
    required this.id,
    required this.reference,
    this.status,
    required this.items,
    required this.totals,
    this.family,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  List<OrderTimelineStep> get timeline {
    final current = status ?? OrderStatus.pending;
    final steps = current == OrderStatus.cancelled
        ? OrderStatus.cancelledFlow
        : OrderStatus.flow;
    final reached = steps.indexOf(current);

    return [
      for (var i = 0; i < steps.length; i++)
        OrderTimelineStep(
          status: steps[i],
          done: i <= reached,
          at: i == 0
              ? createdAt
              : i == reached
                  ? updatedAt
                  : null,
        ),
    ];
  }

  @override
  List<Object?> get props => [
        id,
        reference,
        status,
        items,
        totals,
        family,
        notes,
        createdAt,
        updatedAt,
      ];
}

class OrdersQuery extends Equatable {
  final int? page;

  const OrdersQuery({this.page});

  Map<String, dynamic> toQueryParameters() => {'page': ?page};

  @override
  List<Object?> get props => [page];
}
