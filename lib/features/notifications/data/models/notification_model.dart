import '../../../../core/domain/paged.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    super.type,
    required super.isRead,
    required super.title,
    required super.body,
    required super.createdDisplay,
    super.target,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        type: NotificationType.fromWire(json['type']),
        isRead: json['is_read'] as bool? ?? true,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdDisplay: json['created_display'] as String? ?? '',
        target: _target(jsonMapOrNull(json['target'])),
      );

  static NotificationTarget? _target(Map<String, dynamic>? json) {
    if (json == null) return null;
    final kind = NotificationTargetKind.fromWire(json['kind']);
    final id = json['id'];
    if (kind == null || id is! String || id.isEmpty) return null;
    return NotificationTarget(kind: kind, id: id);
  }
}

class NotificationFeedModel extends NotificationFeed {
  const NotificationFeedModel({
    required super.page,
    required super.unreadCount,
  });

  factory NotificationFeedModel.fromJson(Map<String, dynamic> json) {
    final items = [
      for (final item in jsonList(json['items']))
        NotificationModel.fromJson(item),
    ];

    return NotificationFeedModel(
      page: Paged<AppNotification>(
        items: items,
        nextCursor: json['next_cursor'] as String?,
      ),
      unreadCount: jsonInt(json['unread_count']) ??
          items.where((notification) => !notification.isRead).length,
    );
  }
}
