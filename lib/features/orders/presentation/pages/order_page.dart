import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../catalog/domain/entities/image_ref.dart';
import '../../../reviews/presentation/widgets/review_sheet.dart';
import '../../domain/entities/order.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../widgets/order_header_card.dart';
import '../widgets/order_items_section.dart';
import '../widgets/order_timeline.dart';

class OrderPage extends StatelessWidget {
  static const String latest = OrderCubit.latest;

  final String orderId;
  final Map<String, ImageRef> productPhotos;

  const OrderPage({
    super.key,
    required this.orderId,
    this.productPhotos = const {},
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey('${context.locale.languageCode}/$orderId'),
      create: (_) => sl<OrderCubit>()..load(orderId),
      child: _OrderView(productPhotos: productPhotos),
    );
  }
}

class _OrderView extends StatelessWidget {
  final Map<String, ImageRef> productPhotos;

  const _OrderView({required this.productPhotos});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_order'.tr(),
            title: 'title_order'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<OrderCubit, OrderState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage &&
                  current.order != null,
              listener: (context, state) => showAppToast(
                context,
                state.errorMessage!,
                isError: true,
              ),
              builder: _buildBody,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderState state) {
    final cubit = context.read<OrderCubit>();
    final order = state.order;

    switch (state.status) {
      case OrderViewStatus.initial:
      case OrderViewStatus.loading:
        return const LoadingView();
      case OrderViewStatus.empty:
        return EmptyState(icon: AppIcons.bag, title: 'orders_empty'.tr());
      case OrderViewStatus.error:
        return ErrorView(
          message: state.errorMessage ?? 'order_failed'.tr(),
          onRetry: cubit.refresh,
        );
      case OrderViewStatus.loaded:
        if (order == null) return const LoadingView();
    }

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          OrderHeaderCard(
            reference: order.reference,
            subtitle: order.family?.name,
          ),
          OrderTimeline(steps: order.timeline),
          OrderItemsSection(
            items: order.items,
            totalDisplay: order.totals.total.display,
            productPhotos: productPhotos,
            onReview: state.canReview
                ? (line) => _review(context, state, line)
                : null,
            reviewedProductIds: state.reviews.keys.toSet(),
          ),
          if (state.canCancel) _buildCancel(context, state),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCancel(BuildContext context, OrderState state) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
        child: AppButton(
          label: 'order_cancel'.tr(),
          style: AppButtonStyle.outline,
          isLoading: state.isCancelling,
          onPressed: () => _confirmCancel(context),
        ),
      );

  Future<void> _review(
    BuildContext context,
    OrderState state,
    OrderLine line,
  ) async {
    final productId = line.productId;
    final order = state.order;
    if (productId == null || order == null) return;

    final cubit = context.read<OrderCubit>();
    final saved = await showReviewSheet(
      context,
      ReviewTarget(
        productId: productId,
        productName: line.name,
        orderId: order.id,
        existing: state.reviews[productId],
      ),
    );
    if (saved == null || !context.mounted) return;
    cubit.reviewSaved(productId, saved);
    showAppToast(context, 'review_saved'.tr());
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final cubit = context.read<OrderCubit>();
    final confirmed = await showConfirmSheet(
      context,
      title: 'order_cancel_title'.tr(),
      body: 'order_cancel_body'.tr(),
      confirmLabel: 'order_cancel'.tr(),
    );
    if (confirmed) await cubit.cancel();
  }
}
