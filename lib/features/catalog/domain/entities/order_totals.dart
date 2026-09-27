import 'package:equatable/equatable.dart';

import '../../../../core/utils/money.dart';

class OrderTotals extends Equatable {
  final Money subtotal;
  final Money discount;
  final Money shipping;
  final Money total;

  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.shipping,
    required this.total,
  });

  @override
  List<Object?> get props => [subtotal, discount, shipping, total];
}
