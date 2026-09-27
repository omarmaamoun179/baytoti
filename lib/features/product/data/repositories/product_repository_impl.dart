import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ProductDetail>> getProduct(String productId) =>
      _dataSource.getProduct(productId);
}
