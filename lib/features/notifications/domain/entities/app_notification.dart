import 'package:equatable/equatable.dart';

enum NotificationType {
  ratingRequest('rating_request', ['review', 'rating']),
  exhibition('exhibition', ['exhibition', 'bazaar']),
  offer('offer', ['offer', 'coupon', 'discount', 'promo']),
  support('support', ['support', 'ticket']),
  orderStatus('order_status', ['order', 'deliver', 'ship', 'payment']),
  familyUpdate('family_update', ['store', 'family', 'product']);

  final String tag;
  final List<String> keywords;

  const NotificationType(this.tag, this.keywords);

  String get tagKey => 'notification_tag_$tag';

  static NotificationType? classify(Iterable<String?> words) {
    final subject = words.whereType<String>().join(' ').toLowerCase();
    if (subject.isEmpty) return null;

    for (final type in values) {
      if (type.keywords.any(subject.contains)) return type;
    }
    return null;
  }
}

enum NotificationTargetKind {
  order(['order']),
  product(['product']),
  family(['store', 'family']);

  final List<String> keywords;

  const NotificationTargetKind(this.keywords);

  static NotificationTargetKind? fromEntity(String? entity) {
    final subject = entity?.toLowerCase();
    if (subject == null || subject.isEmpty) return null;

    for (final kind in values) {
      if (kind.keywords.any(subject.contains)) return kind;
    }
    return null;
  }
}

class NotificationTarget extends Equatable {
  final NotificationTargetKind kind;
  final String handle;

  const NotificationTarget({required this.kind, required this.handle});

  @override
  List<Object?> get props => [kind, handle];
}

class AppNotification extends Equatable {
  final String id;
  final NotificationType? type;
  final String? title;
  final String? body;
  final DateTime? readAt;
  final DateTime? createdAt;
  final NotificationTarget? target;

  const AppNotification({
    required this.id,
    this.type,
    this.title,
    this.body,
    this.readAt,
    this.createdAt,
    this.target,
  });

  bool get isRead => readAt != null;

  String? get headline => title ?? body;

  String? get detail => title == null ? null : body;

  @override
  List<Object?> get props =>
      [id, type, title, body, readAt, createdAt, target];
}

class NotificationsQuery extends Equatable {
  final int? page;

  const NotificationsQuery({this.page});

  Map<String, dynamic> toQueryParameters() => {'page': ?page};

  @override
  List<Object?> get props => [page];
}
