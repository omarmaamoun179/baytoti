import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../entities/product_summary.dart';
import '../repositories/favourites_repository.dart';

class GetFavouritesUseCase
    implements UseCase<Either<Failure, List<ProductSummary>>, NoParams> {
  final FavouritesRepository _repository;

  GetFavouritesUseCase(this._repository);

  @override
  Future<Either<Failure, List<ProductSummary>>> call(NoParams params) =>
      _repository.getFavourites();
}

class SetFavouriteParams extends Equatable {
  final String productId;
  final bool favourite;

  const SetFavouriteParams({required this.productId, required this.favourite});

  @override
  List<Object?> get props => [productId, favourite];
}

class SetFavouriteUseCase
    implements UseCase<Either<Failure, bool>, SetFavouriteParams> {
  final FavouritesRepository _repository;

  SetFavouriteUseCase(this._repository);

  @override
  Future<Either<Failure, bool>> call(SetFavouriteParams params) =>
      _repository.setFavourite(params.productId, params.favourite);
}
