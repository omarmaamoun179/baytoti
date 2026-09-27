import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../domain/entities/app_notification.dart';

enum NotificationsStatus { initial, loading, loaded, error }

class NotificationsState extends Equatable {
  final NotificationsStatus status;
  final Paged<AppNotification> page;
  final bool isLoadingMore;
  final String? errorMessage;

  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.page = const Paged<AppNotification>(),
    this.isLoadingMore = false,
    this.errorMessage,
  });

  List<AppNotification> get notifications => page.items;

  bool get isLoaded => status == NotificationsStatus.loaded;

  NotificationsState copyWith({
    NotificationsStatus? status,
    Paged<AppNotification>? page,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, page, isLoadingMore, errorMessage];
}
