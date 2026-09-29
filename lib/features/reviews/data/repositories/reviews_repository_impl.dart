import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../product/domain/entities/product_detail.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/repositories/reviews_repository.dart';
import '../datasources/reviews_data_source.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  final ReviewsDataSource _dataSource;

  ReviewsRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, Review>> submit(ReviewDraft draft) =>
      _dataSource.submit(draft);
}
