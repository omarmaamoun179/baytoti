import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'order_state.dart';

class OrderCubit extends BaseCubit<OrderState> {
  static const String latest = 'latest';

  final GetOrdersUseCase _getOrders;
  final GetOrderUseCase _getOrder;
  final CancelOrderUseCase _cancelOrder;

  String? _requestedId;

  OrderCubit(this._getOrders, this._getOrder, this._cancelOrder)
      : super(const OrderState());

  Future<void> load(String orderId) async {
    _requestedId = orderId;
    emit(state.copyWith(
      status: state.order == null ? OrderViewStatus.loading : state.status,
    ));

    if (orderId != latest) return _loadOrder(orderId);

    final result = await _getOrders(const OrdersQuery());
    final page = result.fold(
      (failure) {
        _fail(failure);
        return null;
      },
      (page) => page,
    );
    if (page == null) return;

    if (page.isEmpty) {
      emit(state.copyWith(status: OrderViewStatus.empty));
      return;
    }
    await _loadOrder(page.items.first.id);
  }

  Future<void> refresh() async {
    final order = state.order;
    if (order != null) return _loadOrder(order.id);

    final requested = _requestedId;
    if (requested != null) await load(requested);
  }

  Future<void> cancel() async {
    final order = state.order;
    if (order == null || !state.canCancel || state.isCancelling) return;
    emit(state.copyWith(isCancelling: true));

    final result = await _cancelOrder(order.id);

    result.fold(
      (failure) => emit(state.copyWith(
        isCancelling: false,
        errorMessage: failure.message,
      )),
      (cancelled) => emit(state.copyWith(
        isCancelling: false,
        order: cancelled,
      )),
    );
  }

  Future<void> _loadOrder(String orderId) async {
    final result = await _getOrder(orderId);

    result.fold(
      _fail,
      (order) => emit(state.copyWith(
        status: OrderViewStatus.loaded,
        order: order,
      )),
    );
  }

  void _fail(Failure failure) => emit(state.copyWith(
        status: state.order == null ? OrderViewStatus.error : state.status,
        errorMessage: failure.message,
      ));
}
