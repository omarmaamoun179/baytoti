import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../../domain/entities/explore_feed.dart';
import '../../domain/repositories/explore_repository.dart';
import '../datasources/explore_data_source.dart';

class ExploreRepositoryImpl implements ExploreRepository {
  final ExploreDataSource _dataSource;

  ExploreRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, ExploreFeed>> getExplore(
    ExploreTab tab, {
    String? cursor,
  }) =>
      _dataSource.getExplore(tab, cursor: cursor);
}
