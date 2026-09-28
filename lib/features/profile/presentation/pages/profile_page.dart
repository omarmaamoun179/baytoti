import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/localization_service.dart';
import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/navigation_extension.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/confirm_sheet.dart';
import '../../../auth/domain/entities/customer.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';
import '../widgets/profile_identity.dart';
import '../widgets/profile_row.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<ProfileCubit>()..load(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final session = context.select((AuthCubit cubit) => cubit.state.customer);

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(kicker: 'kicker_profile'.tr(), title: 'title_profile'.tr()),
          Expanded(
            child: MultiBlocListener(
              listeners: [
                BlocListener<ProfileCubit, ProfileState>(
                  listenWhen: (previous, current) =>
                      current.customer != null &&
                      current.customer != previous.customer,
                  listener: (context, state) =>
                      context.read<AuthCubit>().updateCustomer(state.customer!),
                ),
                BlocListener<ProfileCubit, ProfileState>(
                  listenWhen: (_, current) => current.errorMessage != null,
                  listener: (context, state) =>
                      showAppToast(context, state.errorMessage!, isError: true),
                ),
              ],
              child: BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) => RefreshIndicator(
                  color: p.accent,
                  onRefresh: context.read<ProfileCubit>().load,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      _buildIdentity(session ?? state.customer),
                      ..._buildRows(context),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentity(Customer? customer) => ProfileIdentity(
    name: customer?.fullName ?? '',
    phone: customer?.phone ?? '',
    avatarUrl: customer?.avatarUrl,
  );

  List<Widget> _buildRows(BuildContext context) => [
        ProfileRow(
          label: 'profile_edit'.tr(),
          onTap: () => context.pushInTab(AppRoutes.editProfileSegment),
        ),
        ProfileRow(
          label: 'profile_my_orders'.tr(),
          onTap: () => context.pushInTab(AppRoutes.orderSegment),
        ),
        ProfileRow(
          label: 'profile_favourites'.tr(),
          onTap: () => context.pushInTab(AppRoutes.favouritesSegment),
        ),
        ProfileRow(
          label: 'profile_addresses'.tr(),
          onTap: () => context.pushInTab(AppRoutes.addressesSegment),
        ),
        ProfileRow(
          label: 'profile_location'.tr(),
          onTap: () =>
              context.push(AppRoutes.locationFor(from: context.currentLocation)),
        ),
        ProfileRow(
          label: 'profile_notifications'.tr(),
          onTap: () => context.openNotifications(),
        ),
        ProfileRow(
          label: 'profile_language'.tr(),
          meta: 'profile_language_value'.tr(),
          onTap: () => _switchLanguage(context),
        ),
        ProfileRow(
          label: 'profile_sign_out'.tr(),
          isSignOut: true,
          onTap: () => _signOut(context),
        ),
      ];

  Future<void> _switchLanguage(BuildContext context) async {
    final cart = context.read<CartCubit>();
    final code = context.locale.languageCode == 'ar' ? 'en' : 'ar';

    await LocalizationService.change(context, sl<CacheService>(), code);
    await cart.load();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showConfirmSheet(
      context,
      title: 'profile_sign_out_title'.tr(),
      body: 'profile_sign_out_body'.tr(),
      confirmLabel: 'profile_sign_out'.tr(),
    );
    if (!confirmed || !context.mounted) return;

    final auth = context.read<AuthCubit>();
    final router = GoRouter.of(context);
    await auth.signOut();
    router.go(AppRoutes.welcome);
  }
}
