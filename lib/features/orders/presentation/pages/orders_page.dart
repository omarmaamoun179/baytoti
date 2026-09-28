import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/paged_scroll_listener.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/orders_cubit.dart';
import '../cubit/orders_state.dart';
import '../widgets/order_summary_tile.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<OrdersCubit>()..load(),
      child: const _OrdersView(),
    );
  }
}

class _OrdersView extends StatelessWidget {
  const _OrdersView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_orders'.tr(),
            title: 'title_orders'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<OrdersCubit, OrdersState>(
              listenWhen: (_, current) =>
                  current.isLoaded && current.errorMessage != null,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) => switch (state.status) {
                OrdersStatus.initial || OrdersStatus.loading =>
                  const LoadingView(),
                OrdersStatus.error => ErrorView(
                    message: state.errorMessage,
                    onRetry: context.read<OrdersCubit>().load,
                  ),
                OrdersStatus.loaded => _buildList(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, OrdersState state) {
    final cubit = context.read<OrdersCubit>();
    final orders = state.orders;

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.load,
      child: PagedScrollListener(
        isLoading: state.isLoadingMore,
        onEndOfPage: cubit.loadMore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (orders.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.bag,
                  title: 'orders_empty'.tr(),
                  message: 'orders_empty_sub'.tr(),
                ),
              )
            else
              SliverList.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) => OrderSummaryTile(
                  key: ValueKey(orders[index].id),
                  order: orders[index],
                  onTap: () => _open(context, cubit, orders[index].id),
                ),
              ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: LoadingView(padding: EdgeInsets.symmetric(vertical: 18)),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    OrdersCubit cubit,
    String orderId,
  ) async {
    await context.openOrder(orderId);
    if (!cubit.isClosed) await cubit.load();
  }
}
