import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/domain/entities/cart.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../cart/presentation/widgets/totals_table.dart';
import '../../domain/entities/checkout.dart';
import '../cubit/checkout_cubit.dart';
import '../cubit/checkout_state.dart';
import '../widgets/address_card.dart';
import '../widgets/address_sheet.dart';
import '../widgets/checkout_pay_footer.dart';
import '../widgets/checkout_section.dart';
import '../widgets/checkout_step_strip.dart';
import '../widgets/fulfilment_selector.dart';
import '../widgets/payment_method_list.dart';

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

  Future<void> _onPlaced(BuildContext context, PlacedOrder order) async {
    final cart = context.read<CartCubit>();
    final redirect = order.paymentRedirect;

    if (redirect != null) {
      try {
        await sl<LauncherService>().openWebsite(redirect);
      } catch (e, s) {
        logError(e, s, reason: 'CheckoutPage.openPaymentRedirect');
      }
    }
    if (context.mounted) {
      context.go('${AppRoutes.cart}/${AppRoutes.orderSegment}/${order.orderId}');
    }
    await cart.load();
  }

  Future<void> _changeAddress(BuildContext context, CheckoutState state) async {
    final options = state.options;
    if (options == null || state.isBusy) return;
    final cubit = context.read<CheckoutCubit>();

    final picked = await showAddressSheet(
      context,
      addresses: options.addresses,
      selectedId: state.addressId,
    );
    if (picked != null) cubit.selectAddress(picked);
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
                      previous.placedOrder == null &&
                      current.placedOrder != null,
                  listener: (context, state) =>
                      _onPlaced(context, state.placedOrder!),
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
    final options = state.options;

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
        if (options == null) return const LoadingView();
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
        return _buildForm(context, state, options, cart);
      },
    );
  }

  Widget _buildForm(
    BuildContext context,
    CheckoutState state,
    CheckoutOptions options,
    Cart cart,
  ) {
    final cubit = context.read<CheckoutCubit>();
    final address = state.address;
    final fee = state.fulfilment?.feeFils;
    final totals = fee == null
        ? cart.totals
        : cart.totals.withShipping(fee, context.locale.languageCode);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const CheckoutStepStrip(),
        CheckoutSection(
          label: 'checkout_address'.tr(),
          actionLabel: options.addresses.isEmpty ? null : 'checkout_change'.tr(),
          onAction: () => _changeAddress(context, state),
          child: address == null
              ? AddressCard(label: 'checkout_no_address'.tr())
              : AddressCard(label: address.label, line: address.line),
        ),
        CheckoutSection(
          label: 'checkout_fulfilment'.tr(),
          child: FulfilmentSelector(
            methods: options.fulfilmentMethods,
            selectedId: state.fulfilmentId,
            onSelect: cubit.selectFulfilment,
          ),
        ),
        CheckoutSection(
          label: 'checkout_payment'.tr(),
          child: PaymentMethodList(
            methods: options.paymentMethods,
            selectedId: state.paymentId,
            onSelect: cubit.selectPayment,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: TotalsTable(totals: totals),
        ),
        CheckoutPayFooter(
          totalDisplay: totals.total.display,
          isLoading: state.isBusy,
          onPay: state.canPlace ? () => cubit.placeOrder(cart.id) : null,
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
