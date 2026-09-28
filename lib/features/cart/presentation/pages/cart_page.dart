import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/cart.dart';
import '../cart_actions.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_line_tile.dart';
import '../widgets/totals_table.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    final cubit = context.read<CartCubit>();
    if (cubit.state.status != CartStatus.loading) cubit.load();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(kicker: 'kicker_cart'.tr(), title: 'title_cart'.tr()),
          Expanded(
            child: BlocConsumer<CartCubit, CartState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage &&
                  current.cart != null,
              listener: (context, state) {
                if (ModalRoute.of(context)?.isCurrent == false) return;
                showAppToast(context, state.errorMessage!, isError: true);
              },
              builder: _buildBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CartState state) {
    final cubit = context.read<CartCubit>();
    final cart = state.cart;

    if (cart == null) {
      if (state.status != CartStatus.error) return const LoadingView();
      return ErrorView(
        message: state.errorMessage ?? 'cart_failed'.tr(),
        onRetry: cubit.load,
      );
    }

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: cart.isEmpty
            ? [
                EmptyState(
                  icon: AppIcons.bag,
                  title: 'cart_empty'.tr(),
                  message: 'cart_empty_sub'.tr(),
                ),
              ]
            : _buildLines(context, state, cart),
      ),
    );
  }

  List<Widget> _buildLines(BuildContext context, CartState state, Cart cart) {
    return [
      for (final item in cart.items)
        CartLineTile(
          key: ValueKey(item.id),
          item: item,
          busy: state.isBusy(item.id),
          onQuantity: (quantity) => setCartQuantity(context, item, quantity),
          onRemove: () => removeFromCart(context, item),
        ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: TotalsTable(totals: cart.totals),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: AppButton(
          label: 'cart_checkout'.tr(),
          trailingText: cart.totals.total.display,
          onPressed: () => context.pushInTab(AppRoutes.checkoutSegment),
        ),
      ),
      const SizedBox(height: 12),
    ];
  }
}
