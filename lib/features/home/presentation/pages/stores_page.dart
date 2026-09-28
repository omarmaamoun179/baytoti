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
import '../../../../core/widgets/state_views.dart';
import '../../../location/domain/entities/location.dart';
import '../cubit/stores_cubit.dart';
import '../widgets/trusted_store_card.dart';

class StoresPage extends StatelessWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<StoresCubit>()..load(),
      child: BlocListener<LocationCubit, LocationContext>(
        listenWhen: (previous, current) => current.movedFrom(previous),
        listener: (context, _) => context.read<StoresCubit>().load(),
        child: const _StoresView(),
      ),
    );
  }
}

class _StoresView extends StatelessWidget {
  const _StoresView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_stores'.tr(),
            title: 'title_stores'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<StoresCubit, StoresState>(
              listenWhen: (_, current) =>
                  current.isLoaded && current.errorMessage != null,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) => switch (state.status) {
                StoresStatus.initial || StoresStatus.loading =>
                  const LoadingView(),
                StoresStatus.error => ErrorView(
                    message: state.errorMessage,
                    onRetry: context.read<StoresCubit>().load,
                  ),
                StoresStatus.loaded => _buildList(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, StoresState state) {
    final stores = state.stores;

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: context.read<StoresCubit>().load,
      child: stores.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                EmptyState(
                  icon: AppIcons.home,
                  title: 'stores_empty'.tr(),
                  message: 'stores_empty_sub'.tr(),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              itemCount: stores.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => TrustedStoreCard(
                key: ValueKey(stores[index].family.id),
                store: stores[index],
                onTap: () => context.openFamily(stores[index].family.slug),
              ),
            ),
    );
  }
}
