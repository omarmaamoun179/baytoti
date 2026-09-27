import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/domain/usecases/favourite_usecases.dart';

enum FavouritesStatus { initial, loading, loaded, error }

class FavouritesState extends Equatable {
  final FavouritesStatus status;
  final List<ProductSummary> products;
  final String? errorMessage;

  const FavouritesState({
    this.status = FavouritesStatus.initial,
    this.products = const [],
    this.errorMessage,
  });

  bool get isLoaded => status == FavouritesStatus.loaded;

  FavouritesState copyWith({
    FavouritesStatus? status,
    List<ProductSummary>? products,
    String? errorMessage,
  }) {
    return FavouritesState(
      status: status ?? this.status,
      products: products ?? this.products,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, products, errorMessage];
}

class FavouritesCubit extends BaseCubit<FavouritesState> {
  final GetFavouritesUseCase _getFavourites;
  final SetFavouriteUseCase _setFavourite;

  FavouritesCubit(this._getFavourites, this._setFavourite)
      : super(const FavouritesState());

  Future<void> load() async {
    final hadList = state.isLoaded;
    if (!hadList) emit(state.copyWith(status: FavouritesStatus.loading));

    final result = await _getFavourites(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: hadList ? null : FavouritesStatus.error,
        errorMessage: failure.message,
      )),
      (products) => emit(state.copyWith(
        status: FavouritesStatus.loaded,
        products: products,
      )),
    );
  }

  Future<void> remove(ProductSummary product) async {
    final before = state.products;
    if (!before.contains(product)) return;
    emit(state.copyWith(products: [...before]..remove(product)));

    final result = await _setFavourite(
      SetFavouriteParams(productId: product.id, favourite: false),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        products: before,
        errorMessage: failure.message,
      )),
      (_) {},
    );
  }
}
