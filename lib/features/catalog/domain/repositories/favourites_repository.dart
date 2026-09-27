import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/product_summary.dart';

abstract class FavouritesRepository {
  Future<Either<Failure, List<ProductSummary>>> getFavourites();

  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite);
}
