import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/paged_scroll_listener.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../cart/presentation/cart_actions.dart';
import '../../domain/entities/family_profile.dart';
import '../cubit/family_cubit.dart';
import '../cubit/family_state.dart';
import '../widgets/family_header.dart';
import '../widgets/family_product_row.dart';
import '../widgets/family_stats.dart';

class FamilyPage extends StatelessWidget {
  final String familyId;

  const FamilyPage({super.key, required this.familyId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<FamilyCubit>()..load(familyId),
      child: const _FamilyView(),
    );
  }
}

class _FamilyView extends StatelessWidget {
  const _FamilyView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return BlocListener<FamilyCubit, FamilyState>(
      listenWhen: (_, current) =>
          current.status == FamilyStatus.loaded &&
          current.errorMessage != null,
      listener: (context, state) =>
          showAppToast(context, state.errorMessage!, isError: true),
      child: Scaffold(
        backgroundColor: p.bg,
        body: Column(
          children: [
            AppHeader(
              kicker: 'kicker_family'.tr(),
              title: 'title_family'.tr(),
              onBack: () => context.pop(),
            ),
            Expanded(
              child: BlocBuilder<FamilyCubit, FamilyState>(
                builder: (context, state) {
                  final family = state.family;
                  if (state.status == FamilyStatus.loaded && family != null) {
                    return _buildLoaded(context, state, family);
                  }
                  if (state.status == FamilyStatus.error) {
                    return ErrorView(
                      message: state.errorMessage,
                      onRetry: context.read<FamilyCubit>().retry,
                    );
                  }
                  return const LoadingView();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    FamilyState state,
    FamilyProfile family,
  ) {
    final cubit = context.read<FamilyCubit>();
    final products = state.products.items;
    final rows = (products.length + 1) ~/ 2;

    return PagedScrollListener(
      isLoading: state.isLoadingMore,
      onEndOfPage: cubit.loadMore,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FamilyHeader(family: family),
                FamilyStats(
                  productCount: state.productCount,
                  rating: family.rating,
                ),
                if (products.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: SectionLabel('family_products'.tr()),
                  ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: rows,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: FamilyProductRow.gap),
              itemBuilder: (context, row) => FamilyProductRow(
                products: products.skip(row * 2).take(2).toList(),
                onOpen: (product) => context.openProduct(product.slug),
                onAdd: (product) => addToCart(context, product.id),
              ),
            ),
          ),
          if (state.isLoadingMore)
            const SliverToBoxAdapter(
              child: LoadingView(padding: EdgeInsets.only(top: 16)),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: products.isEmpty ? 12 : 28),
          ),
        ],
      ),
    );
  }
}
