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
import '../../../../core/widgets/pill_chip.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../../domain/entities/explore_feed.dart';
import '../cubit/explore_cubit.dart';
import '../cubit/explore_state.dart';
import '../widgets/explore_tab_strip.dart';
import '../widgets/most_viewed_tile.dart';
import '../widgets/rising_row.dart';

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
    final feed = state.feed;

    if (feed == null) {
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
        sliver: SliverMainAxisGroup(
          slivers: feed.isEmpty
              ? [
                  SliverToBoxAdapter(
                    child: EmptyState(
                      icon: AppIcons.explore,
                      title: 'explore_empty'.tr(),
                      message: 'explore_empty_sub'.tr(),
                    ),
                  ),
                ]
              : _buildFeed(context, feed),
        ),
      ),
      if (state.isLoadingMore)
        const SliverToBoxAdapter(
          child: LoadingView(padding: EdgeInsets.symmetric(vertical: 16)),
        ),
    ];
  }

  List<Widget> _buildFeed(BuildContext context, ExploreFeed feed) {
    final languageCode = context.locale.languageCode;

    return [
      if (feed.hashtags.isNotEmpty)
        SliverToBoxAdapter(
          child: ChipStrip(
            children: [
              for (final tag in feed.hashtags) PillChip.tag(label: tag),
            ],
          ),
        ),
      if (feed.rising.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: SectionLabel('explore_top_rising'.tr()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList.builder(
            itemCount: feed.rising.length,
            itemBuilder: (context, index) {
              final item = feed.rising[index];
              return RisingRow(
                item: item,
                languageCode: languageCode,
                onTap: () => context.openProduct(item.product.id),
              );
            },
          ),
        ),
      ],
      if (feed.mostViewed.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: SectionLabel('explore_most_viewed'.tr()),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: feed.mostViewed.length,
            itemBuilder: (context, index) {
              final product = feed.mostViewed[index];
              return MostViewedTile(
                product: product,
                onTap: () => context.openProduct(product.id),
              );
            },
          ),
        ),
      ],
    ];
  }
}
