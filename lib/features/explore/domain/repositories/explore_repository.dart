import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/explore_feed.dart';

abstract class ExploreRepository {
  Future<Either<Failure, ExploreFeed>> getExplore(
    ExploreTab tab, {
    String? cursor,
  });
}
