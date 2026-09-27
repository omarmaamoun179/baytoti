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
import '../../../../core/widgets/stat_grid.dart';
import '../../../auth/domain/entities/customer.dart';
import '../../domain/entities/profile.dart';
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
  static const String _latestOrder = 'latest';
  static const String _pending = '—';

  const _ProfileView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final customer = context.select((AuthCubit cubit) => cubit.state.customer);

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
                      current.profile != null &&
                      current.profile != previous.profile,
                  listener: (context, state) => context
                      .read<AuthCubit>()
                      .updateCustomer(state.profile!.customer),
                ),
                BlocListener<ProfileCubit, ProfileState>(
                  listenWhen: (_, current) => current.errorMessage != null,
                  listener: (context, state) => showAppToast(
                    context,
                    state.errorMessage!,
                    isError: true,
                  ),
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
                      _buildIdentity(state.profile, customer),
                      _buildStats(state.profile?.stats),
                      ..._buildRows(context, state.profile?.stats),
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

  Widget _buildIdentity(Profile? profile, Customer? customer) =>
      ProfileIdentity(
        name: profile?.fullName ?? customer?.fullName ?? '',
        phone: profile?.phone ?? customer?.phone ?? '',
        avatarUrl: profile?.avatarUrl ?? customer?.avatarUrl,
      );

  Widget _buildStats(ProfileStats? stats) => StatGrid(
        items: [
          StatItem(
            stats == null ? _pending : '${stats.orderCount}',
            'profile_stat_orders'.tr(),
          ),
          StatItem(
            stats == null ? _pending : '${stats.favouriteCount}',
            'profile_stat_favourites'.tr(),
          ),
          StatItem(
            stats == null ? _pending : '${stats.followingCount}',
            'profile_stat_following'.tr(),
          ),
        ],
      );

  List<Widget> _buildRows(BuildContext context, ProfileStats? stats) => [
        ProfileRow(
          label: 'profile_my_orders'.tr(),
          meta: stats == null ? null : '${stats.orderCount}',
          onTap: () => context.openOrder(_latestOrder),
        ),
        ProfileRow(
          label: 'profile_favourites_following'.tr(),
          meta: stats == null ? null : '${stats.favouritesAndFollowing}',
          onTap: () => context.go(AppRoutes.explore),
        ),
        ProfileRow(
          label: 'profile_addresses'.tr(),
          onTap: () =>
              context.go('${AppRoutes.cart}/${AppRoutes.checkoutSegment}'),
        ),
        ProfileRow(
          label: 'profile_notifications'.tr(),
          onTap: () => context.openNotifications(),
        ),
        ProfileRow(
          label: 'profile_support'.tr(),
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
