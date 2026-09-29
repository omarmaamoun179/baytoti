import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../../product/domain/entities/product_detail.dart';
import '../entities/review_draft.dart';
import '../repositories/reviews_repository.dart';

class SubmitReviewUseCase
    implements UseCase<Either<Failure, Review>, ReviewDraft> {
  final ReviewsRepository _repository;

  SubmitReviewUseCase(this._repository);

  @override
  Future<Either<Failure, Review>> call(ReviewDraft draft) =>
      _repository.submit(draft);
}
