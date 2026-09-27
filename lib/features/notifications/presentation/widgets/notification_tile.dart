import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/app_notification.dart';

class NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;

  const NotificationTile({super.key, required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unread = !notification.isRead;

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
                    Text(
                      notification.title,
                      style: AppStrings.w800(12.5, 1.35).c(p.text),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: AppStrings.w400(11.5, 1.6).c(p.neutral700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                notification.createdDisplay,
                style: AppStrings.w400(10, 1).c(p.neutral600),
              ),
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
