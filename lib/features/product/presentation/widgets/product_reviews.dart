import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../reviews/presentation/widgets/review_sheet.dart';
import '../../domain/entities/product_detail.dart';

class ProductReviews extends StatelessWidget {
  final ProductDetail product;
  final List<Review> reviews;
  final Review? mine;
  final ValueChanged<Review> onSaved;

  const ProductReviews({
    super.key,
    required this.product,
    required this.reviews,
    this.mine,
    required this.onSaved,
  });

  Future<void> _write(BuildContext context) async {
    final saved = await showReviewSheet(
      context,
      ReviewTarget(
        productId: product.id,
        productName: product.name,
        existing: mine,
      ),
    );
    if (saved == null || !context.mounted) return;
    onSaved(saved);
    showAppToast(context, 'review_saved'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final mine = this.mine;
    final others = [
      for (final review in reviews)
        if (review.id != mine?.id) review,
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: SectionLabel('product_reviews'.tr())),
              AppTextButton(
                label: (mine == null ? 'review_add' : 'review_edit').tr(),
                onPressed: () => _write(context),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (mine != null) ReviewCard(review: mine, isMine: true),
          for (final review in others) ReviewCard(review: review),
          if (mine == null && others.isEmpty)
            Text(
              'product_reviews_empty'.tr(),
              style: AppStrings.w400(12, 1.6).c(p.neutral600),
            ),
        ],
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isMine;

  const ReviewCard({super.key, required this.review, this.isMine = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMine ? p.accent100 : p.surface,
        border: Border.all(color: isMine ? p.accent200 : p.divider),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isMine ? 'review_yours'.tr() : review.authorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStrings.w800(12, 1).c(isMine ? p.accent700 : p.text),
                ),
              ),
              const SizedBox(width: 8),
              Text(review.stars, style: AppStrings.w800(11, 1).c(p.accent)),
            ],
          ),
          if (review.body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              review.body,
              style: AppStrings.w400(12, 1.6).c(p.neutral800),
            ),
          ],
        ],
      ),
    );
  }
}
