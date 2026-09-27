import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../utils/app_strings.dart';
import 'app_icon.dart';
import 'section_label.dart';

class AppHeader extends StatelessWidget {
  final String title;
  final String? kicker;
  final VoidCallback? onBack;
  final List<Widget> actions;

  const AppHeader({
    super.key,
    required this.title,
    this.kicker,
    this.onBack,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, top + 10, 16, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: p.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            if (onBack != null) ...[
              HeaderIconButton(
                icon: AppIcons.back,
                iconSize: 15,
                strokeWidth: 2.4,
                onTap: onBack!,
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kicker != null)
                    SectionLabel(
                      kicker!,
                      size: 9,
                      tracking: .18,
                      color: p.accent,
                    ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStrings.w800(19, 1.25).c(p.text),
                  ),
                ],
              ),
            ),
            for (final action in actions) ...[
              const SizedBox(width: 10),
              action,
            ],
          ],
        ),
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  final AppIconData icon;
  final VoidCallback onTap;
  final double iconSize;
  final double strokeWidth;
  final bool showDot;

  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconSize = 16,
    this.strokeWidth = 1.8,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: p.divider),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AppIcon(
                icon,
                size: iconSize,
                color: p.text,
                strokeWidth: strokeWidth,
              ),
              if (showDot)
                PositionedDirectional(
                  top: -8,
                  end: -8,
                  child: Container(width: 7, height: 7, color: p.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
