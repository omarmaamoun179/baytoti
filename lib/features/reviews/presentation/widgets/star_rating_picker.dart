import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../domain/entities/review_draft.dart';

class StarRatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int>? onChanged;
  final bool hasError;

  const StarRatingPicker({
    super.key,
    required this.value,
    this.onChanged,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = ReviewDraft.minRating;
            star <= ReviewDraft.maxRating;
            star++)
          Semantics(
            button: true,
            selected: star <= value,
            label: 'review_rating_$star'.tr(),
            child: InkResponse(
              onTap: onChanged == null ? null : () => onChanged!(star),
              radius: 26,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: AppIcon(
                  AppIcons.star,
                  size: 34,
                  strokeWidth: 1.6,
                  filled: star <= value,
                  color: star <= value
                      ? p.accent
                      : hasError
                          ? p.danger
                          : p.neutral400,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
