import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/app_notification.dart';

String notificationTimeLabel(DateTime at, {required DateTime now}) {
  final local = at.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');

  if (local.year == now.year &&
      local.month == now.month &&
      local.day == now.day) {
    return '${two(local.hour)}:${two(local.minute)}';
  }
  if (local.year == now.year) return '${local.day}/${local.month}';
  return '${local.day}/${local.month}/${local.year}';
}

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unread = !notification.isRead;
    final headline = notification.headline;
    final detail = notification.detail;
    final createdAt = notification.createdAt;

    return Material(
      color: unread ? p.accent100 : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(border: Border(bottom: p.hairline)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTag(p, unread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (headline != null)
                      Text(
                        headline,
                        style: AppStrings.w800(12.5, 1.35).c(p.text),
                      ),
                    if (detail != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: AppStrings.w400(11.5, 1.6).c(p.neutral700),
                      ),
                    ],
                  ],
                ),
              ),
              if (createdAt != null) ...[
                const SizedBox(width: 12),
                Text(
                  notificationTimeLabel(createdAt, now: DateTime.now()),
                  style: AppStrings.w400(10, 1).c(p.neutral600),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(AppPalette p, bool unread) {
    final type = notification.type;

    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      color: unread ? p.accent : p.neutral200,
      child: Text(
        type == null ? '' : type.tagKey.tr(),
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.center,
        style: AppStrings.w800(11, 1).c(unread ? p.onAccent : p.neutral800),
      ),
    );
  }
}
