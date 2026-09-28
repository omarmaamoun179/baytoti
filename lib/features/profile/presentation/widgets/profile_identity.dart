import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/phone.dart';
import '../../../../core/widgets/avatar_photo.dart';

class ProfileIdentity extends StatelessWidget {
  final String name;
  final String phone;
  final String? avatarUrl;

  const ProfileIdentity({
    super.key,
    required this.name,
    required this.phone,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.rule)),
      child: Row(
        children: [
          AvatarPhoto(url: avatarUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: AppStrings.w800(17, 1.2).c(p.text)),
                const SizedBox(height: 4),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    displayPhone(phone),
                    style: AppStrings.w400(12, 1.4).c(p.neutral700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
