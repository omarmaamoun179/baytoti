import 'dart:async';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/notifications_usecases.dart';
import 'notifications_state.dart';

class NotificationsCubit extends BaseCubit<NotificationsState> {
  final GetNotificationsUseCase _getNotifications;
  final MarkNotificationsReadUseCase _markRead;

  int _generation = 0;
  Future<void>? _firstPage;

  NotificationsCubit(this._getNotifications, this._markRead)
      : super(const NotificationsState());

  Future<void> load() =>
      _firstPage ??= _readFirstPage().whenComplete(() => _firstPage = null);

  Future<void> _readFirstPage() async {
    _generation++;
    final hadList = state.isLoaded;
    emit(state.copyWith(
      status: hadList ? null : NotificationsStatus.loading,
      isLoadingMore: false,
    ));

    final result = await _getNotifications(const NotificationsQuery());

    result.fold(
      (failure) => emit(state.copyWith(
        status: hadList ? null : NotificationsStatus.error,
        errorMessage: failure.message,
      )),
      (feed) {
        emit(state.copyWith(
          status: NotificationsStatus.loaded,
          page: feed.page,
          isLoadingMore: false,
        ));
        if (feed.hasUnread) unawaited(_markRead(NoParams()));
      },
    );
  }

  Future<void> loadMore() async {
    if (_firstPage != null ||
        !state.isLoaded ||
        state.isLoadingMore ||
        !state.page.hasMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getNotifications(
      NotificationsQuery(page: state.page.nextPage),
    );
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (feed) => emit(state.copyWith(
        page: state.page.append(feed.page),
        isLoadingMore: false,
      )),
    );
  }
}
