import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../cubit/favourites_cubit.dart';
import '../widgets/favourites_grid.dart';

class FavouritesPage extends StatelessWidget {
  const FavouritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<FavouritesCubit>()..load(),
      child: const _FavouritesView(),
    );
  }
}

class _FavouritesView extends StatelessWidget {
  const _FavouritesView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_favourites'.tr(),
            title: 'title_favourites'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<FavouritesCubit, FavouritesState>(
              listenWhen: (_, current) =>
                  current.isLoaded && current.errorMessage != null,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) => switch (state.status) {
                FavouritesStatus.initial || FavouritesStatus.loading =>
                  const LoadingView(),
                FavouritesStatus.error => ErrorView(
                    message: state.errorMessage,
                    onRetry: context.read<FavouritesCubit>().load,
                  ),
                FavouritesStatus.loaded => _buildList(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, FavouritesState state) {
    final cubit = context.read<FavouritesCubit>();

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          if (state.products.isEmpty)
            EmptyState(
              icon: AppIcons.heart,
              title: 'favourites_empty'.tr(),
              message: 'favourites_empty_sub'.tr(),
              action: AppButton(
                label: 'favourites_browse'.tr(),
                pill: true,
                onPressed: () => context.go(AppRoutes.explore),
              ),
            )
          else
            FavouritesGrid(
              products: state.products,
              onOpen: (product) => context.openProduct(product.slug),
              onAdd: (product) => addToCart(context, product.id),
              onRemove: cubit.remove,
            ),
        ],
      ),
    );
  }
}
