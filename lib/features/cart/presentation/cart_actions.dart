import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/failure.dart';
import '../../../core/routing/navigation_extension.dart';
import '../../../core/routing/routes.dart';
import '../../../core/widgets/app_toast.dart';
import '../../auth/presentation/cubit/auth_cubit.dart';
import '../domain/entities/cart.dart';
import 'cubit/cart_cubit.dart';

Future<void> addToCart(
  BuildContext context,
  String productId, {
  int quantity = 1,
  bool openCart = false,
}) async {
  if (!requireSignIn(context)) return;

  final failure = await context.read<CartCubit>().add(productId, quantity);
  if (!context.mounted) return;

  if (failure != null) {
    showAppToast(
      context,
      failure.message ?? 'cart_update_failed'.tr(),
      isError: true,
    );
    return;
  }

  if (openCart) {
    context.go(AppRoutes.cart);
  } else {
    showAppToast(context, 'cart_added'.tr());
  }
}

Future<void> setCartQuantity(
  BuildContext context,
  CartItem item,
  int quantity,
) =>
    _reportFailure(
      context,
      context.read<CartCubit>().setQuantity(item, quantity),
    );

Future<void> removeFromCart(BuildContext context, CartItem item) =>
    _reportFailure(context, context.read<CartCubit>().remove(item));

Future<void> _reportFailure(
  BuildContext context,
  Future<Failure?> action,
) async {
  final failure = await action;
  if (failure == null || !context.mounted) return;
  showAppToast(
    context,
    failure.message ?? 'cart_update_failed'.tr(),
    isError: true,
  );
}

bool requireSignIn(BuildContext context) {
  if (context.read<AuthCubit>().state.isSignedIn) return true;
  showAppToast(context, 'sign_in_required'.tr());
  context.openAuth();
  return false;
}
