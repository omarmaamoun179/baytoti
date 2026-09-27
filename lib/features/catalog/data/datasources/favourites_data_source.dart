import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/product_summary.dart';
import '../models/catalog_models.dart';

abstract class FavouritesDataSource {
  Future<Either<Failure, Set<String>>> getFavouriteIds();

  Future<Either<Failure, List<ProductSummary>>> getFavourites();

  Future<Either<Failure, bool>> setFavourite(String productId, bool favourite);
}

class FavouritesRemoteDataSource implements FavouritesDataSource {
  final NetworkService _network;

  FavouritesRemoteDataSource(this._network);

  @override
  Future<Either<Failure, Set<String>>> getFavouriteIds() => guardedRequest(
        'FavouritesRemoteDataSource.getFavouriteIds',
        () async => (await _read()).productIds,
        fallbackMessage: 'favourite_failed',
      );

  @override
  Future<Either<Failure, List<ProductSummary>>> getFavourites() =>
      guardedRequest(
        'FavouritesRemoteDataSource.getFavourites',
        () async => (await _read()).products,
        fallbackMessage: 'favourite_failed',
      );

  @override
  Future<Either<Failure, bool>> setFavourite(
    String productId,
    bool favourite,
  ) =>
      guardedRequest(
        'FavouritesRemoteDataSource.setFavourite',
        () => favourite ? _add(productId) : _remove(productId),
        fallbackMessage: 'favourite_failed',
      );

  Future<bool> _add(String productId) async {
    final response = await _network.post(
      ApiEndPoint.wishlistItems,
      data: {'product_id': int.tryParse(productId) ?? productId},
    );
    final wishlist = _Wishlist.maybeFrom(checkedResponse(response).json);
    return wishlist == null || wishlist.holds(productId);
  }

  Future<bool> _remove(String productId) async {
    final row = (await _read()).rowFor(productId);
    if (row == null) return false;

    checkedResponse(await _network.delete(ApiEndPoint.wishlistItem(row)));
    return false;
  }

  Future<_Wishlist> _read() async {
    final response = await _network.get(ApiEndPoint.wishlist);
    final wishlist = _Wishlist.maybeFrom(checkedResponse(response).json);
    if (wishlist == null) {
      throw const FormatException('the wishlist answer has no items');
    }
    return wishlist;
  }
}

class _Wishlist {
  final Map<String, String> _rowByProduct;
  final List<ProductSummary> products;

  const _Wishlist(this._rowByProduct, this.products);

  static _Wishlist? maybeFrom(Map<String, dynamic> json) {
    final rows = json['items'] ?? json['data'];
    if (rows is! List) return null;

    final rowByProduct = <String, String>{};
    final products = <ProductSummary>[];
    for (final row in jsonList(rows)) {
      final id = jsonId(row['id']);
      final product = jsonId(row['product_id'] ?? row['product']);
      if (id == null || product == null) continue;
      rowByProduct[product] = id;
      final details = jsonMapOrNull(row['product']);
      if (details != null) {
        products.add(
          ProductSummaryModel.fromJson(details).copyWith(isFavourite: true),
        );
      }
    }
    return _Wishlist(rowByProduct, products);
  }

  Set<String> get productIds => _rowByProduct.keys.toSet();

  bool holds(String productId) => _rowByProduct.containsKey(productId);

  String? rowFor(String productId) => _rowByProduct[productId];
}
