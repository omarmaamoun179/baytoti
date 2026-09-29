import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../product/domain/entities/product_detail.dart';
import '../entities/review_draft.dart';

abstract class ReviewsRepository {
  Future<Either<Failure, Review>> submit(ReviewDraft draft);
}
