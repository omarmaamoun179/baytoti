import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_icon.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppStrings.w600(14, 1.2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(border: Border(bottom: p.hairline)),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: p.surface,
          border: Border.all(color: p.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AppIcon(AppIcons.search, size: 15, color: p.text),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                textInputAction: TextInputAction.search,
                cursorColor: p.accent,
                style: style.c(p.text),
                decoration: InputDecoration.collapsed(
                  hintText: 'search_placeholder'.tr(),
                  hintStyle: style.c(p.neutral600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
