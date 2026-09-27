import '../../../../core/domain/paged.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    super.type,
    super.title,
    super.body,
    super.readAt,
    super.createdAt,
    super.target,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final data = jsonMap(json['data']);
    final entity = _text(data['entity']);

    return NotificationModel(
      id: jsonId(json['id']) ?? '',
      type: NotificationType.classify(
        [_text(json['type']), entity, _text(data['action'])],
      ),
      title: _text(json['title']) ?? _text(data['title']),
      body: _text(json['body']) ?? _text(data['body']),
      readAt: _date(json['read_at']),
      createdAt: _date(json['created_at']),
      target: _target(entity, data),
    );
  }

  static Paged<AppNotification> pageFrom(Map<String, dynamic> json) {
    final meta = jsonMap(json['meta']);
    final items = [
      for (final row in jsonList(json['data'])) NotificationModel.fromJson(row),
    ];

    return Paged<AppNotification>(
      items: [
        for (final item in items)
          if (item.id.isNotEmpty) item,
      ],
      currentPage: jsonCount(meta['current_page']) ?? 1,
      lastPage: jsonCount(meta['last_page']) ?? 1,
      total: jsonCount(meta['total']),
    );
  }

  static NotificationTarget? _target(
    String? entity,
    Map<String, dynamic> data,
  ) {
    final kind = NotificationTargetKind.fromEntity(entity);
    final handle = switch (kind) {
      NotificationTargetKind.order => jsonId(data['entity_id']),
      NotificationTargetKind.product ||
      NotificationTargetKind.family =>
        _text(data['slug']),
      null => null,
    };
    if (kind == null || handle == null) return null;
    return NotificationTarget(kind: kind, handle: handle);
  }

  static String? _text(Object? value) => switch (jsonString(value)?.trim()) {
        final String text when text.isNotEmpty => text,
        _ => null,
      };

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
