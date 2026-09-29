import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../catalog/data/datasources/favourites_data_source.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;
  final FavouritesDataSource _favourites;

  ProductRepositoryImpl(this._dataSource, this._favourites);

  @override
  Future<Either<Failure, ProductDetail>> getProduct(String slug) async {
    final favouritesRequest = _favourites.getFavouriteIds();
    final product = await _dataSource.getProduct(slug);
    final favourites = await favouritesRequest;

    return product.map(
      (product) => favourites.fold(
        (_) => product,
        (ids) => product.copyWith(isFavourite: ids.contains(product.id)),
      ),
    );
  }

  @override
  Future<Either<Failure, ReviewDigest>> getReviews(ReviewsQuery query) =>
      _dataSource.getReviews(query);
}
