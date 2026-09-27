import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/paged_scroll_listener.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/explore_tab_strip.dart';
import '../widgets/product_grid_sliver.dart';

class ExplorePage extends StatelessWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<ExploreCubit>()..load(),
      child: const _ExploreView(),
    );
  }
}

class _ExploreView extends StatelessWidget {
  const _ExploreView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_explore'.tr(),
            title: 'title_explore'.tr(),
            actions: [
              HeaderIconButton(
                icon: AppIcons.bell,
                showDot: true,
                onTap: () {
                  if (requireSignIn(context)) context.openNotifications();
                },
              ),
            ],
          ),
          Expanded(
            child: BlocConsumer<ExploreCubit, ExploreState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.status == ExploreStatus.loaded,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) {
                final cubit = context.read<ExploreCubit>();

                return PagedScrollListener(
                  isLoading: state.isLoadingMore,
                  onEndOfPage: cubit.loadMore,
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ExploreTabStrip(
                          selected: state.tab,
                          onSelect: cubit.selectTab,
                        ),
                      ),
                      ..._buildBody(context, state),
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(BuildContext context, ExploreState state) {
    final products = state.products;

    if (products == null) {
      return [
        SliverToBoxAdapter(
          child: state.status == ExploreStatus.error
              ? ErrorView(
                  message: state.errorMessage,
                  onRetry: context.read<ExploreCubit>().load,
                )
              : const LoadingView(),
        ),
      ];
    }

    return [
      SliverOpacity(
        opacity: state.isSwitching ? .45 : 1,
        sliver: products.isEmpty
            ? SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.explore,
                  title: 'explore_empty'.tr(),
                  message: 'explore_empty_sub'.tr(),
                ),
              )
            : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
                sliver: ProductGridSliver(
                  products: products.items,
                  onOpen: (product) => context.openProduct(product.slug),
                  onAdd: (product) => addToCart(context, product.id),
                ),
              ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: LoadingView(padding: EdgeInsets.symmetric(vertical: 16)),
        ),
    ];
  }
}
