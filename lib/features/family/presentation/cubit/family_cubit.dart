import '../../../../core/abstract/base_cubit.dart';
import '../../domain/usecases/family_usecases.dart';
import 'family_state.dart';

class FamilyCubit extends BaseCubit<FamilyState> {
  final GetFamilyUseCase _getFamily;
  final GetFamilyProductsUseCase _getProducts;
  final SetFollowingUseCase _setFollowing;

  String _familyId = '';
  int _generation = 0;

  FamilyCubit(this._getFamily, this._getProducts, this._setFollowing)
      : super(const FamilyState());

  Future<void> load(String familyId) async {
    _familyId = familyId;
    final generation = ++_generation;
    emit(state.copyWith(status: FamilyStatus.loading, isLoadingMore: false));

    final familyRequest = _getFamily(familyId);
    final productsRequest = _getProducts(
      FamilyProductsParams(familyId: familyId),
    );
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

  Future<void> retry() => load(_familyId);

  Future<void> loadMore() async {
    final cursor = state.products.nextCursor;
    if (!state.canLoadMore || cursor == null) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getProducts(
      FamilyProductsParams(familyId: _familyId, cursor: cursor),
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

  Future<void> toggleFollow() async {
    final family = state.family;
    if (family == null || state.isSavingFollow) return;
    final following = !family.isFollowing;

    emit(state.copyWith(
      family: family.withFollowing(following),
      isSavingFollow: true,
    ));

    final result = await _setFollowing(
      SetFollowingParams(familyId: family.id, following: following),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        family: state.family?.withFollowing(family.isFollowing),
        isSavingFollow: false,
        errorMessage: failure.message,
      )),
      (confirmed) => emit(state.copyWith(
        family: state.family?.withFollowing(confirmed),
        isSavingFollow: false,
      )),
    );
  }
}
