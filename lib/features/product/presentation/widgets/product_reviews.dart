import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/product_detail.dart';

class ProductReviews extends StatelessWidget {
  final List<Review> reviews;

  const ProductReviews({super.key, required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel('product_reviews'.tr()),
          const SizedBox(height: 10),
          for (final review in reviews) ReviewCard(review: review),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;

  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border.all(color: p.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.w800(12, 1).c(p.text),
                ),
              ),
              const SizedBox(width: 8),
              Text(review.stars, style: AppStrings.w800(11, 1).c(p.accent)),
            ],
          ),
          const SizedBox(height: 6),
          Text(review.body, style: AppStrings.w400(12, 1.6).c(p.neutral800)),
        ],
      ),
    );
  }
}
