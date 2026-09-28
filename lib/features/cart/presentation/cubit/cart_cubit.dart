import 'package:dartz/dartz.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/app/session_notifier.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/cart.dart';
import '../../domain/usecases/cart_usecases.dart';
import 'cart_state.dart';

class CartCubit extends BaseCubit<CartState> {
  final GetCartUseCase _getCart;
  final AddToCartUseCase _addToCart;
  final UpdateCartItemUseCase _updateItem;
  final RemoveCartItemUseCase _removeItem;
  final SessionNotifier _session;

  bool? _wasSignedIn;

  CartCubit(
    this._getCart,
    this._addToCart,
    this._updateItem,
    this._removeItem,
    this._session,
  ) : super(const CartState()) {
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  void _onSessionChanged() {
    if (!_session.isResolved) return;
    final signedIn = _session.isAuthenticated;
    if (signedIn == _wasSignedIn) return;
    _wasSignedIn = signedIn;

    if (signedIn) {
      load();
    } else {
      emit(const CartState());
    }
  }

  Future<void> load() async {
    if (!_session.isAuthenticated) return;
    emit(state.copyWith(
      status: state.cart == null ? CartStatus.loading : state.status,
    ));

    final result = await _getCart(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.cart == null ? CartStatus.error : CartStatus.loaded,
        errorMessage: failure.message,
      )),
      (cart) => emit(state.copyWith(status: CartStatus.loaded, cart: cart)),
    );
  }

  Future<Failure?> add(String productId, int quantity) async {
    emit(state.copyWith(isAdding: true));

    final result = await _addToCart(
      CartQuantityParams(id: productId, quantity: quantity),
    );

    return result.fold(
      (failure) {
        emit(state.copyWith(isAdding: false));
        return failure;
      },
      (cart) {
        emit(state.copyWith(
          status: CartStatus.loaded,
          cart: cart,
          isAdding: false,
        ));
        return null;
      },
    );
  }

  Future<Failure?> setQuantity(CartItem item, int quantity) async {
    if (quantity < 1 || quantity > item.maxQuantity || state.isBusy(item.id)) {
      return null;
    }
    return _mutate(
      item.id,
      () => _updateItem(CartQuantityParams(id: item.id, quantity: quantity)),
    );
  }

  Future<Failure?> remove(CartItem item) async {
    if (state.isBusy(item.id)) return null;
    return _mutate(item.id, () => _removeItem(item.id));
  }

  Future<Failure?> _mutate(
    String itemId,
    Future<Either<Failure, Cart>> Function() call,
  ) async {
    emit(state.copyWith(busyItemIds: {...state.busyItemIds, itemId}));

    final result = await call();
    final busy = {...state.busyItemIds}..remove(itemId);

    return result.fold(
      (failure) {
        emit(state.copyWith(busyItemIds: busy));
        return failure;
      },
      (cart) {
        emit(state.copyWith(cart: cart, busyItemIds: busy));
        return null;
      },
    );
  }

  @override
  Future<void> close() {
    _session.removeListener(_onSessionChanged);
    return super.close();
  }
}
