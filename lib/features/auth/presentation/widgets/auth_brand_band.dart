import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';

class AuthBrandBand extends StatelessWidget {
  const AuthBrandBand({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 8),
      child: Column(
        children: [
          Text('بيتوتي', style: AppStrings.w800(30, 1).c(p.accent)),
          const SizedBox(height: 8),
          Text(
            'BAYTOUTI',
            style: AppStrings.w800(9, 1).c(p.accent).spaced(9 * .24),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Text(
              'auth_intro'.tr(),
              textAlign: TextAlign.center,
              style: AppStrings.w400(12.5, 1.65).c(p.accent),
            ),
          ),
        ],
      ),
    );
  }
}
