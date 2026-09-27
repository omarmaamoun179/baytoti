import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/presentation/widgets/totals_table.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/presentation/pages/order_page.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/address_card.dart';
import '../widgets/address_sheet.dart';
import '../widgets/checkout_pay_footer.dart';
import '../widgets/checkout_section.dart';

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<CheckoutCubit>()..load(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatelessWidget {
  const _CheckoutView();

  Future<void> _onPlaced(
    BuildContext context,
    List<OrderSummary> orders,
  ) async {
    final cart = context.read<CartCubit>();
    final orderId = orders.firstOrNull?.id ?? OrderPage.latest;

    context.go('${AppRoutes.cart}/${AppRoutes.orderSegment}/$orderId');
    await cart.load();
  }

  Future<void> _changeAddress(BuildContext context, CheckoutState state) async {
    final addresses = state.addresses;
    if (addresses == null || state.isBusy) return;
    final cubit = context.read<CheckoutCubit>();

    final picked = await showAddressSheet(
      context,
      addresses: addresses,
      selectedId: state.addressId,
      onAdd: () => _addAddress(context),
    );
    if (picked != null) cubit.selectAddress(picked);
  }

  Future<void> _addAddress(BuildContext context) async {
    final cubit = context.read<CheckoutCubit>();
    if (cubit.state.isBusy) return;

    final saved = await context.push<bool>(
      '${AppRoutes.cart}/${AppRoutes.addressesSegment}/${AppRoutes.newSegment}',
    );
    if (saved == true) await cubit.addressAdded();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_checkout'.tr(),
            title: 'title_checkout'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<CheckoutCubit, CheckoutState>(
                  listenWhen: (previous, current) =>
                      current.errorMessage != null &&
                      current.errorMessage != previous.errorMessage &&
                      current.status == CheckoutStatus.loaded,
                  listener: (context, state) => showAppToast(
                    context,
                    state.errorMessage!,
                    isError: true,
                  ),
                ),
                BlocListener<CheckoutCubit, CheckoutState>(
                  listenWhen: (previous, current) =>
                      previous.placedOrders == null &&
                      current.placedOrders != null,
                  listener: (context, state) =>
                      _onPlaced(context, state.placedOrders!),
                ),
              ],
              child: BlocBuilder<CheckoutCubit, CheckoutState>(
                builder: _buildBody,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CheckoutState state) {
    switch (state.status) {
      case CheckoutStatus.initial:
      case CheckoutStatus.loading:
        return const LoadingView();
      case CheckoutStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'checkout_failed'.tr(),
          onRetry: context.read<CheckoutCubit>().load,
        );
      case CheckoutStatus.loaded:
        break;
    }

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        final cart = cartState.cart;
        if (cart == null) {
          if (cartState.status != CartStatus.error) return const LoadingView();
          return ErrorView(
            message: 'cart_failed'.tr(),
            onRetry: context.read<CartCubit>().load,
          );
        }
        if (cart.isEmpty && !state.isBusy) {
          return EmptyState(
            icon: AppIcons.bag,
            title: 'cart_empty'.tr(),
            message: 'cart_empty_sub'.tr(),
          );
        }
        return _buildForm(context, state, cart);
      },
    );
  }

  Widget _buildForm(BuildContext context, CheckoutState state, Cart cart) {
    final cubit = context.read<CheckoutCubit>();
    final address = state.address;
    final hasAddresses = state.addresses?.isNotEmpty ?? false;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        CheckoutSection(
          label: 'checkout_address'.tr(),
          actionLabel: hasAddresses ? 'checkout_change'.tr() : null,
          onAction: () => _changeAddress(context, state),
          child: address == null
              ? NoAddressCard(
                  onAdd: state.isBusy ? null : () => _addAddress(context),
                )
              : AddressCard(label: address.label, line: address.line),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: TotalsTable(totals: cart.totals),
        ),
        CheckoutPayFooter(
          totalDisplay: cart.totals.total.display,
          isLoading: state.isBusy,
          onPay: state.canPlace ? cubit.placeOrder : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
