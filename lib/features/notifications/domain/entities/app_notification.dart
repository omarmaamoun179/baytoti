import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';

enum NotificationType {
  orderStatus('order_status'),
  offer('offer'),
  exhibition('exhibition'),
  familyUpdate('family_update'),
  ratingRequest('rating_request'),
  support('support');

  final String wire;

  const NotificationType(this.wire);

  String get tagKey => 'notification_tag_$wire';

  static NotificationType? fromWire(Object? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

enum NotificationTargetKind {
  order('order'),
  family('family'),
  product('product');

  final String wire;

  const NotificationTargetKind(this.wire);

  static NotificationTargetKind? fromWire(Object? value) {
    for (final kind in values) {
      if (kind.wire == value) return kind;
    }
    return null;
  }
}

class NotificationTarget extends Equatable {
  final NotificationTargetKind kind;
  final String id;

  const NotificationTarget({required this.kind, required this.id});

  @override
  List<Object?> get props => [kind, id];
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType? type;
  final bool isRead;
  final String title;
  final String body;
  final String createdDisplay;
  final NotificationTarget? target;

  const AppNotification({
    required this.id,
    this.type,
    required this.isRead,
    required this.title,
    required this.body,
    required this.createdDisplay,
    this.target,
  });

  @override
  List<Object?> get props =>
      [id, type, isRead, title, body, createdDisplay, target];
}

class NotificationFeed extends Equatable {
  final Paged<AppNotification> page;
  final int unreadCount;

  const NotificationFeed({required this.page, required this.unreadCount});

  bool get hasUnread =>
      unreadCount > 0 || page.items.any((notification) => !notification.isRead);

  @override
  List<Object?> get props => [page, unreadCount];
}

class NotificationsQuery extends Equatable {
  final int? page;

  const NotificationsQuery({this.page});

  Map<String, dynamic> toQueryParameters() => {'page': ?page};

  @override
  List<Object?> get props => [page];
}
