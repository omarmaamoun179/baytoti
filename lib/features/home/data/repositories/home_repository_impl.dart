import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_data_source.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeDataSource _dataSource;

  HomeRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, HomeFeed>> getHome() => _dataSource.getHome();
}
