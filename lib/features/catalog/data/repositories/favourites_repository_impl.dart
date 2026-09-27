import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/repositories/favourites_repository.dart';
import '../datasources/favourites_data_source.dart';

class FavouritesRepositoryImpl implements FavouritesRepository {
  final FavouritesDataSource _dataSource;

  FavouritesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, bool>> setFavourite(
    String productId,
    bool favourite,
  ) =>
      _dataSource.setFavourite(productId, favourite);
}
