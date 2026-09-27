import '../../../../core/abstract/base_cubit.dart';
import '../../domain/usecases/family_usecases.dart';
import 'family_state.dart';

class FamilyCubit extends BaseCubit<FamilyState> {
  final GetFamilyUseCase _getFamily;
  final GetFamilyProductsUseCase _getProducts;

  String _slug = '';
  int _generation = 0;

  FamilyCubit(this._getFamily, this._getProducts)
      : super(const FamilyState());

  Future<void> load(String slug) async {
    _slug = slug;
    final generation = ++_generation;
    emit(state.copyWith(status: FamilyStatus.loading, isLoadingMore: false));

    final familyRequest = _getFamily(slug);
    final productsRequest = _getProducts(FamilyProductsParams(slug: slug));
    final familyResult = await familyRequest;
    final productsResult = await productsRequest;
    if (generation != _generation) return;

    familyResult.fold(
      (failure) => emit(state.copyWith(
        status: FamilyStatus.error,
        errorMessage: failure.message,
      )),
      (family) => productsResult.fold(
        (failure) => emit(state.copyWith(
          status: FamilyStatus.error,
          errorMessage: failure.message,
        )),
        (products) => emit(state.copyWith(
          status: FamilyStatus.loaded,
          family: family,
          products: products,
        )),
      ),
    );
  }

  Future<void> retry() => load(_slug);

  Future<void> loadMore() async {
    if (!state.canLoadMore) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getProducts(
      FamilyProductsParams(slug: _slug, page: state.products.nextPage),
    );
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        isLoadingMore: false,
        products: state.products.append(page),
      )),
    );
  }
}
