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
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/address.dart';
import '../cubit/addresses_cubit.dart';
import '../widgets/address_tile.dart';

class AddressesPage extends StatelessWidget {
  const AddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressesCubit>()..load(),
      child: const _AddressesView(),
    );
  }
}

class _AddressesView extends StatelessWidget {
  const _AddressesView();

  Future<void> _openForm(BuildContext context, [Address? address]) async {
    final cubit = context.read<AddressesCubit>();
    final saved = await context.push<bool>(
      '${context.currentTab}/${AppRoutes.addressesSegment}/'
      '${AppRoutes.newSegment}',
      extra: address,
    );
    if (saved == true) await cubit.load();
  }

  Future<void> _delete(BuildContext context, Address address) async {
    final cubit = context.read<AddressesCubit>();
    final confirmed = await showConfirmSheet(
      context,
      title: 'address_delete_title'.tr(),
      body: 'address_delete_body'.tr(args: [address.title]),
      confirmLabel: 'address_delete'.tr(),
    );
    if (confirmed) await cubit.delete(address.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_addresses'.tr(),
            title: 'title_addresses'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<AddressesCubit, AddressesState>(
              listenWhen: (previous, current) =>
                  current.errorMessage != null &&
                  current.errorMessage != previous.errorMessage &&
                  current.isLoaded,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) => switch (state.status) {
                AddressesStatus.loading => const LoadingView(),
                AddressesStatus.error => ErrorView(
                    message: state.errorMessage ?? 'addresses_failed'.tr(),
                    onRetry: context.read<AddressesCubit>().load,
                  ),
                AddressesStatus.loaded => _buildList(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, AddressesState state) {
    final cubit = context.read<AddressesCubit>();

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          if (state.isEmpty)
            EmptyState(
              icon: AppIcons.home,
              title: 'addresses_empty'.tr(),
              message: 'addresses_empty_sub'.tr(),
            ),
          for (final address in state.addresses) ...[
            AddressTile(
              address: address,
              isBusy: state.isBusy(address.id),
              onEdit: () => _openForm(context, address),
              onDelete: () => _delete(context, address),
              onMakeDefault: () => cubit.makeDefault(address.id),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          AppButton(
            label: 'address_add'.tr(),
            trailingIcon: AppIcons.plus,
            style: state.isEmpty
                ? AppButtonStyle.primary
                : AppButtonStyle.outline,
            onPressed: () => _openForm(context),
          ),
        ],
      ),
    );
  }
}
