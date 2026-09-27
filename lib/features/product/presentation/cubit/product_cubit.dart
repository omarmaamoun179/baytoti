import '../../../../core/abstract/base_cubit.dart';
import '../../../catalog/domain/usecases/favourite_usecases.dart';
import '../../domain/entities/product_detail.dart';
import '../../domain/usecases/product_usecases.dart';
import 'product_state.dart';

class ProductCubit extends BaseCubit<ProductState> {
  final GetProductUseCase _getProduct;
  final SetFavouriteUseCase _setFavourite;

  String _productId = '';

  ProductCubit(this._getProduct, this._setFavourite)
      : super(const ProductState());

  Future<void> load(String productId) async {
    _productId = productId;
    emit(state.copyWith(status: ProductStatus.loading));

    final result = await _getProduct(productId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: ProductStatus.error,
        errorMessage: failure.message,
      )),
      (product) => emit(state.copyWith(
        status: ProductStatus.loaded,
        product: product,
        quantity: _fit(state.quantity, product),
      )),
    );
  }

  Future<void> retry() => load(_productId);

  int _fit(int quantity, ProductDetail product) =>
      product.canOrder ? quantity.clamp(1, product.maxQuantity) : 1;

  void increment() {
    if (state.canIncrement) emit(state.copyWith(quantity: state.quantity + 1));
  }

  void decrement() {
    if (state.canDecrement) emit(state.copyWith(quantity: state.quantity - 1));
  }

  Future<void> toggleFavourite() async {
    final product = state.product;
    if (product == null || state.isSavingFavourite) return;
    final favourite = !product.isFavourite;

    emit(state.copyWith(
      product: product.copyWith(isFavourite: favourite),
      isSavingFavourite: true,
    ));

    final result = await _setFavourite(
      SetFavouriteParams(productId: product.id, favourite: favourite),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        product: state.product?.copyWith(isFavourite: product.isFavourite),
        isSavingFavourite: false,
        errorMessage: failure.message,
      )),
      (confirmed) => emit(state.copyWith(
        product: state.product?.copyWith(isFavourite: confirmed),
        isSavingFavourite: false,
      )),
    );
  }
}
