import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/network/guarded_request.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/type_def.dart';
import '../../../catalog/data/fixtures/fixture_backend.dart';
import '../models/product_detail_model.dart';

abstract class ProductDataSource {
  Future<Either<Failure, ProductDetailModel>> getProduct(String productId);
}

const Map<int, String> _productRenames = {404: 'product_not_found'};

class ProductRemoteDataSource implements ProductDataSource {
  final NetworkService _network;

  ProductRemoteDataSource(this._network);

  @override
  Future<Either<Failure, ProductDetailModel>> getProduct(String productId) =>
      guardedRequest(
        'ProductRemoteDataSource.getProduct',
        () async {
          final response = await _network.get(ApiEndPoint.product(productId));
          return ProductDetailModel.fromJson(checkedResponse(response).json);
        },
        fallbackMessage: 'product_failed',
        messageForStatus: _productRenames,
      );
}

class ProductMockDataSource implements ProductDataSource {
  final FixtureBackend _backend;
  final ContentLanguage _language;

  ProductMockDataSource(this._backend, this._language);

  @override
  Future<Either<Failure, ProductDetailModel>> getProduct(String productId) =>
      guardedRequest(
        'ProductMockDataSource.getProduct',
        () async {
          await _backend.wait();
          return ProductDetailModel.fromJson(
            _backend.product(productId, await _language()),
          );
        },
        fallbackMessage: 'product_failed',
        messageForStatus: _productRenames,
      );
}
