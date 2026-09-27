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
import '../../../catalog/domain/entities/product_summary.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';
import '../widgets/search_field.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_filter_sheets.dart';
import '../widgets/search_result_bar.dart';
import '../widgets/search_result_row.dart';

class SearchPage extends StatelessWidget {
  final String? initialQuery;
  final String? initialCategoryId;

  const SearchPage({super.key, this.initialQuery, this.initialCategoryId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(
        '${context.locale.languageCode}|$initialQuery|$initialCategoryId',
      ),
      create: (_) => sl<SearchCubit>()
        ..load(query: initialQuery, categorySlug: initialCategoryId),
      child: _SearchView(initialQuery: initialQuery ?? ''),
    );
  }
}

class _SearchView extends StatefulWidget {
  final String initialQuery;

  const _SearchView({required this.initialQuery});

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleFavourite(ProductSummary product) {
    if (!requireSignIn(context)) return;
    context.read<SearchCubit>().toggleFavourite(product);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(kicker: 'kicker_search'.tr(), title: 'title_search'.tr()),
          Expanded(
            child: BlocConsumer<SearchCubit, SearchState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.status != SearchStatus.error,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) {
                final cubit = context.read<SearchCubit>();

                return PagedScrollListener(
                  isLoading: state.isLoadingMore,
                  onEndOfPage: cubit.loadMore,
                  child: CustomScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverToBoxAdapter(
                        child: SearchField(
                          controller: _controller,
                          onChanged: cubit.queryChanged,
                          onSubmitted: cubit.submit,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SearchFilterBar(
                          query: state.query,
                          categoryName: state.categoryName,
                          onAll: cubit.clearFilters,
                          onCategory: () => pickCategory(context),
                          onPrice: () => pickPriceOrder(context, state),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: SearchResultBar(
                          total: state.results?.total,
                          sort: state.query.sort,
                          onSort: () => pickSort(context, state),
                        ),
                      ),
                      ..._buildResults(context, state),
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

  List<Widget> _buildResults(BuildContext context, SearchState state) {
    final results = state.results;

    if (state.status == SearchStatus.error) {
      return [
        SliverToBoxAdapter(
          child: ErrorView(
            message: state.errorMessage,
            onRetry: context.read<SearchCubit>().retry,
          ),
        ),
      ];
    }

    if (results == null || results.items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: results == null || state.isRefreshing
              ? const LoadingView()
              : EmptyState(
                  icon: AppIcons.search,
                  title: 'search_empty'.tr(),
                  message: 'search_empty_sub'.tr(),
                ),
        ),
      ];
    }

    return [
      SliverOpacity(
        opacity: state.isRefreshing ? .45 : 1,
        sliver: SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
          sliver: SliverList.builder(
            itemCount: results.items.length,
            itemBuilder: (context, index) {
              final product = results.items[index];
              return SearchResultRow(
                product: product,
                onOpen: () => context.openProduct(product.slug),
                onFavourite: () => _toggleFavourite(product),
              );
            },
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
