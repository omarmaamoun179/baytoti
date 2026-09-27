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
import '../../../../core/widgets/paged_scroll_listener.dart';
import '../../../../core/widgets/state_views.dart';
import '../../domain/entities/app_notification.dart';
import '../cubit/notifications_cubit.dart';
import '../cubit/notifications_state.dart';
import '../widgets/notification_tile.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<NotificationsCubit>()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_notifications'.tr(),
            title: 'title_notifications'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<NotificationsCubit, NotificationsState>(
              listenWhen: (_, current) =>
                  current.isLoaded && current.errorMessage != null,
              listener: (context, state) =>
                  showAppToast(context, state.errorMessage!, isError: true),
              builder: (context, state) => switch (state.status) {
                NotificationsStatus.initial ||
                NotificationsStatus.loading =>
                  const LoadingView(),
                NotificationsStatus.error => ErrorView(
                    message: state.errorMessage,
                    onRetry: context.read<NotificationsCubit>().load,
                  ),
                NotificationsStatus.loaded => _buildList(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, NotificationsState state) {
    final cubit = context.read<NotificationsCubit>();
    final notifications = state.notifications;

    return RefreshIndicator(
      color: context.palette.accent,
      onRefresh: cubit.load,
      child: PagedScrollListener(
        isLoading: state.isLoadingMore,
        onEndOfPage: cubit.loadMore,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (notifications.isEmpty)
              SliverToBoxAdapter(
                child: EmptyState(
                  icon: AppIcons.bell,
                  title: 'notifications_empty'.tr(),
                ),
              )
            else
              SliverList.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) => NotificationTile(
                  key: ValueKey(notifications[index].id),
                  notification: notifications[index],
                  onTap: _openTarget(context, notifications[index].target),
                ),
              ),
            if (state.isLoadingMore)
              const SliverToBoxAdapter(
                child: LoadingView(padding: EdgeInsets.symmetric(vertical: 18)),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        ),
      ),
    );
  }

  VoidCallback? _openTarget(BuildContext context, NotificationTarget? target) {
    if (target == null) return null;

    return switch (target.kind) {
      NotificationTargetKind.order => () => context.openOrder(target.handle),
      NotificationTargetKind.family => () => context.openFamily(target.handle),
      NotificationTargetKind.product => () =>
          context.openProduct(target.handle),
    };
  }
}
