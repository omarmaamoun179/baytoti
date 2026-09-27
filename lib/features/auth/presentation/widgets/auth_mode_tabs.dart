import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../domain/entities/otp_challenge.dart';

class AuthModeTabs extends StatelessWidget {
  final AuthMode mode;
  final ValueChanged<AuthMode> onChanged;

  const AuthModeTabs({super.key, required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    Widget tab(AuthMode value, String label) {
      final selected = value == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(value),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? p.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: selected ? p.cardShadow : null,
            ),
            child: Text(
              label,
              style: AppStrings.w800(12.5, 1)
                  .c(selected ? p.text : p.neutral700),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.neutral200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          tab(AuthMode.login, 'auth_tab_login'.tr()),
          const SizedBox(width: 4),
          tab(AuthMode.signup, 'auth_tab_signup'.tr()),
        ],
      ),
    );
  }
}
