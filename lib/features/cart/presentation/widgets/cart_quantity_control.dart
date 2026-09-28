import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/quantity_stepper.dart';
import '../cart_actions.dart';
import '../cubit/cart_cubit.dart';

class CartQuantityControl extends StatelessWidget {
  final String productId;
  final Widget addButton;
  final double height;

  const CartQuantityControl({
    super.key,
    required this.productId,
    required this.addButton,
    this.height = 30,
  });

  @override
  Widget build(BuildContext context) {
    final (item, busy) = context.select((CartCubit cubit) {
      final item = cubit.state.cart?.itemFor(productId);
      return (item, item != null && cubit.state.isBusy(item.id));
    });
    if (item == null) return addButton;

    return QuantityStepper(
      quantity: item.quantity,
      height: height,
      buttonWidth: 22,
      valueWidth: 22,
      signSize: 14,
      valueSize: 12,
      onDecrement: busy
          ? null
          : () => item.canDecrement
              ? setCartQuantity(context, item, item.quantity - 1)
              : removeFromCart(context, item),
      onIncrement: busy || !item.canIncrement
          ? null
          : () => setCartQuantity(context, item, item.quantity + 1),
    );
  }
}
