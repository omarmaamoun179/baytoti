import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/sheet_error_note.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../../product/domain/entities/product_detail.dart';
import '../../domain/entities/review_draft.dart';
import '../cubit/review_form_cubit.dart';
import 'star_rating_picker.dart';

class ReviewTarget extends Equatable {
  final String productId;
  final String productName;
  final String? orderId;
  final Review? existing;

  const ReviewTarget({
    required this.productId,
    required this.productName,
    this.orderId,
    this.existing,
  });

  @override
  List<Object?> get props => [productId, productName, orderId, existing];
}

Future<Review?> showReviewSheet(BuildContext context, ReviewTarget target) =>
    showModalBottomSheet<Review>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => sl<ReviewFormCubit>(),
        child: ReviewSheet(target: target),
      ),
    );

class ReviewSheet extends StatefulWidget {
  static const Set<String> fields = {'rating', 'comment'};

  final ReviewTarget target;

  const ReviewSheet({super.key, required this.target});

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  late int _rating = widget.target.existing?.rating ?? 0;
  late final TextEditingController _comment =
      TextEditingController(text: widget.target.existing?.body);
  bool _ratingMissing = false;

  String? get _existingId {
    final id = widget.target.existing?.id;
    return id == null || id.isEmpty ? null : id;
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _rate(int rating) {
    setState(() {
      _rating = rating;
      _ratingMissing = false;
    });
    context.read<ReviewFormCubit>().clearFieldError('rating');
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_rating < ReviewDraft.minRating) {
      setState(() => _ratingMissing = true);
      return;
    }

    final target = widget.target;
    context.read<ReviewFormCubit>().save(ReviewDraft(
          productId: target.productId,
          orderId: target.orderId,
          reviewId: _existingId,
          rating: _rating,
          comment: _comment.text,
        ));
  }

  String? _unshownError(ReviewFormState state) {
    final message = state.errorMessage;
    if (message == null) return null;
    if (state.fieldErrors.isEmpty) return message;

    final unshown = [
      for (final entry in state.fieldErrors.entries)
        if (!ReviewSheet.fields.contains(entry.key)) entry.value,
    ];
    return unshown.isEmpty ? null : unshown.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReviewFormCubit, ReviewFormState>(
      listenWhen: (previous, current) => !previous.isSaved && current.isSaved,
      listener: (context, state) => Navigator.of(context).pop(state.saved),
      builder: (context, state) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: _buildForm(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, ReviewFormState state) {
    final p = context.palette;
    final isEdit = _existingId != null;
    final ratingError = _ratingMissing
        ? 'review_rating_required'.tr()
        : state.fieldErrors['rating'];
    final commentError = state.fieldErrors['comment'];
    final note = _unshownError(state);
    final busy = state.isSaving || state.isSaved;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: SheetHandle()),
        Text(
          (isEdit ? 'review_edit_title' : 'review_add_title').tr(),
          style: AppStrings.w800(20, 1.2).c(p.text),
        ),
        const SizedBox(height: 4),
        Text(
          widget.target.productName,
          style: AppStrings.w400(12.5, 1.5).c(p.neutral700),
        ),
        const SizedBox(height: 18),
        StarRatingPicker(
          value: _rating,
          hasError: ratingError != null,
          onChanged: busy ? null : _rate,
        ),
        const SizedBox(height: 6),
        Text(
          _rating == 0
              ? 'review_pick_rating'.tr()
              : 'review_rating_$_rating'.tr(),
          textAlign: TextAlign.center,
          style: AppStrings.w600(12, 1.3).c(p.neutral700),
        ),
        if (ratingError != null)
          Center(child: FieldErrorText(ratingError)),
        const SizedBox(height: 18),
        LabeledField(
          label: 'review_comment'.tr(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _comment,
                enabled: !busy,
                minLines: 3,
                maxLines: 6,
                maxLength: ReviewDraft.commentMaxLength,
                keyboardType: TextInputType.multiline,
                onChanged: (_) => context
                    .read<ReviewFormCubit>()
                    .clearFieldError('comment'),
                style: AppStrings.w600(14, 1.5).c(p.text),
                decoration: fieldDecoration(
                  p,
                  hint: 'review_comment_hint'.tr(),
                  hasError: commentError != null,
                ),
              ),
              if (commentError != null) FieldErrorText(commentError),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 14),
          SheetErrorNote(message: note),
        ],
        const SizedBox(height: 20),
        AppButton(
          label: (isEdit ? 'review_update' : 'review_submit').tr(),
          isLoading: busy,
          onPressed: _submit,
        ),
      ],
    );
  }
}
