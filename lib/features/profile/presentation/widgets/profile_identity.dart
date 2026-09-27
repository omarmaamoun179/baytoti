import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/network_photo.dart';
import '../phone_display.dart';

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
          SizedBox(width: 58, height: 58, child: NetworkPhoto(url: avatarUrl)),
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
                    formatPhoneForDisplay(phone),
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
