import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/home_feed.dart';

abstract class HomeRepository {
  Future<Either<Failure, HomeFeed>> getHome();

  Future<Either<Failure, List<TrustedStore>>> getStores();
}
