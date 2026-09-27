import 'package:dartz/dartz.dart';

import '../../../../core/domain/failure.dart';
import '../entities/search_query.dart';
import '../entities/search_results.dart';

abstract class SearchRepository {
  Future<Either<Failure, SearchResults>> search(SearchQuery query);
}
