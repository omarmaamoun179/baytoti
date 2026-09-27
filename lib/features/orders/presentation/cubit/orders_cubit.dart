import '../../../../core/abstract/base_cubit.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'orders_state.dart';

class OrdersCubit extends BaseCubit<OrdersState> {
  final GetOrdersUseCase _getOrders;

  int _generation = 0;
  Future<void>? _firstPage;

  OrdersCubit(this._getOrders) : super(const OrdersState());

  Future<void> load() =>
      _firstPage ??= _readFirstPage().whenComplete(() => _firstPage = null);

  Future<void> _readFirstPage() async {
    _generation++;
    final hadList = state.isLoaded;
    emit(state.copyWith(
      status: hadList ? null : OrdersStatus.loading,
      isLoadingMore: false,
    ));

    final result = await _getOrders(const OrdersQuery());

    result.fold(
      (failure) => emit(state.copyWith(
        status: hadList ? null : OrdersStatus.error,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: OrdersStatus.loaded,
        page: page,
        isLoadingMore: false,
      )),
    );
  }

  Future<void> loadMore() async {
    if (_firstPage != null ||
        !state.isLoaded ||
        state.isLoadingMore ||
        !state.page.hasMore) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getOrders(OrdersQuery(page: state.page.nextPage));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        page: state.page.append(page),
        isLoadingMore: false,
      )),
    );
  }
}
