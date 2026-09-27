import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';

abstract class FavouritesRepository {
  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite);
}
