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
import '../../domain/entities/home_feed.dart';
import '../cubit/home_cubit.dart';
import '../widgets/best_sellers_grid.dart';
import '../widgets/category_rail.dart';
import '../widgets/exhibition_banner.dart';
import '../widgets/family_rail.dart';
import '../widgets/home_search_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<HomeCubit>()..load(),
      child: const _HomeView(),
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

    return [
      if (feed.banner case final banner?) ExhibitionBanner(banner: banner),
      if (feed.categories.isNotEmpty) _buildCategories(context, feed),
      if (feed.featuredFamilies.isNotEmpty) _buildFamilies(context, feed),
      if (feed.bestSellers.isNotEmpty) _buildBestSellers(context, feed),
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
              AppRoutes.searchFor(categoryId: category.id),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilies(BuildContext context, HomeFeed feed) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      decoration: BoxDecoration(border: Border(top: p.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SectionHeading(
              title: 'home_featured_families'.tr(),
              actionLabel: 'home_see_all'.tr(),
              onAction: () => context.go(AppRoutes.explore),
            ),
          ),
          FamilyRail(
            families: feed.featuredFamilies,
            onTap: (family) => context.openFamily(family.id),
          ),
        ],
      ),
    );
  }

  Widget _buildBestSellers(BuildContext context, HomeFeed feed) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 22),
      decoration: BoxDecoration(border: Border(top: p.rule)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeading(
            title: 'home_best_sellers'.tr(),
            caption: 'home_this_week'.tr(),
          ),
          const SizedBox(height: 12),
          ProductGrid(
            products: feed.bestSellers,
            onOpen: (product) => context.openProduct(product.id),
            onAdd: (product) => addToCart(context, product.id),
          ),
        ],
      ),
    );
  }
}
