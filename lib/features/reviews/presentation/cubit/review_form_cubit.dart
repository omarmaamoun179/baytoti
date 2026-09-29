import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../../product/domain/entities/product_detail.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/usecases/reviews_usecases.dart';

enum ReviewFormStatus { editing, saving, saved }

class ReviewFormState extends Equatable {
  final ReviewFormStatus status;
  final Map<String, String> fieldErrors;
  final Review? saved;
  final String? errorMessage;

  const ReviewFormState({
    this.status = ReviewFormStatus.editing,
    this.fieldErrors = const {},
    this.saved,
    this.errorMessage,
  });

  bool get isSaving => status == ReviewFormStatus.saving;

  bool get isSaved => status == ReviewFormStatus.saved;

  ReviewFormState copyWith({
    ReviewFormStatus? status,
    Map<String, String>? fieldErrors,
    Review? saved,
    String? errorMessage,
  }) {
    return ReviewFormState(
      status: status ?? this.status,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, fieldErrors, saved, errorMessage];
}

class ReviewFormCubit extends BaseCubit<ReviewFormState> {
  final SubmitReviewUseCase _submit;

  ReviewFormCubit(this._submit) : super(const ReviewFormState());

  Future<void> save(ReviewDraft draft) async {
    if (state.isSaving || state.isSaved) return;
    emit(const ReviewFormState(status: ReviewFormStatus.saving));

    final result = await _submit(draft);

    result.fold(
      (failure) => emit(ReviewFormState(
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
        errorMessage: failure.message,
      )),
      (review) => emit(ReviewFormState(
        status: ReviewFormStatus.saved,
        saved: review,
      )),
    );
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    emit(state.copyWith(
      errorMessage: state.errorMessage,
      fieldErrors: {...state.fieldErrors}..remove(field),
    ));
  }
}
