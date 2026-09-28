import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../../../location/domain/entities/location.dart';
import '../../domain/entities/home_feed.dart';
import '../cubit/home_cubit.dart';
import '../widgets/category_rail.dart';
import '../widgets/home_banner_strip.dart';
import '../widgets/home_search_bar.dart';
import '../widgets/home_section.dart';
import '../widgets/product_grid.dart';
import '../widgets/promotion_rail.dart';
import '../widgets/trusted_store_rail.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<HomeCubit>()..load(),
      child: BlocListener<LocationCubit, LocationContext>(
        listenWhen: (previous, current) => current.movedFrom(previous),
        listener: (context, _) => context.read<HomeCubit>().load(),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_home'.tr(),
            title: 'title_home'.tr(),
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
            child: BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) => RefreshIndicator(
                color: p.accent,
                onRefresh: context.read<HomeCubit>().load,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    HomeSearchBar(onTap: () => context.go(AppRoutes.search)),
                    ..._buildContent(context, state),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, HomeState state) {
    final feed = state.feed;

    if (feed == null) {
      return [
        if (state.status == HomeStatus.error)
          ErrorView(
            message: state.errorMessage,
            onRetry: context.read<HomeCubit>().load,
          )
        else
          const LoadingView(),
      ];
    }

    void open(HomeBanner banner) => _openTarget(context, feed, banner.target);

    return [
      if (feed.banners.isNotEmpty)
        HomeBannerStrip(banners: feed.banners, onTap: open),
      if (feed.categories.isNotEmpty) _buildCategories(context, feed),
      if (feed.trustedStores.isNotEmpty)
        HomeSection(
          title: 'home_trusted_stores'.tr(),
          actionLabel: 'home_show_all'.tr(),
          onAction: context.openFamilies,
          child: TrustedStoreRail(
            stores: feed.trustedStores,
            onTap: (store) => context.openFamily(store.family.slug),
          ),
        ),
      if (feed.promotions.isNotEmpty)
        HomeSection(
          title: 'home_offers'.tr(),
          child: PromotionRail(promotions: feed.promotions, onTap: open),
        ),
      if (feed.featuredProducts.isNotEmpty)
        HomeSection(
          title: 'home_featured_products'.tr(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: ProductGrid(
              products: feed.featuredProducts,
              onOpen: (product) => context.openProduct(product.slug),
              onAdd: (product) => addToCart(context, product.id),
            ),
          ),
        ),
    ];
  }

  Widget _buildCategories(BuildContext context, HomeFeed feed) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionLabel('home_categories'.tr()),
          ),
          CategoryRail(
            categories: feed.categories,
            onTap: (category) => context.go(
              AppRoutes.searchFor(categoryId: category.slug),
            ),
          ),
        ],
      ),
    );
  }

  void _openTarget(BuildContext context, HomeFeed feed, HomeTarget? target) {
    final slug = feed.slugOf(target);
    if (target == null || slug == null) return;

    switch (target.kind) {
      case HomeTargetKind.category:
        context.go(AppRoutes.searchFor(categoryId: slug));
      case HomeTargetKind.family:
        context.openFamily(slug);
      case HomeTargetKind.product:
        context.openProduct(slug);
    }
  }
}
