import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/order.dart';
import '../../domain/usecases/orders_usecases.dart';
import 'order_state.dart';

class OrderCubit extends BaseCubit<OrderState> {
  static const String latest = 'latest';

  final GetOrdersUseCase _getOrders;
  final GetOrderUseCase _getOrder;
  final RateOrderUseCase _rateOrder;

  String? _requestedId;

  OrderCubit(this._getOrders, this._getOrder, this._rateOrder)
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

  Future<void> rate(int rating) async {
    final order = state.order;
    if (order == null || !state.showsRating || state.isRating) return;
    if (rating < RateOrderParams.minRating ||
        rating > RateOrderParams.maxRating) {
      return;
    }

    emit(state.copyWith(rating: rating, ratingStatus: RatingStatus.submitting));

    final result = await _rateOrder(
      RateOrderParams(orderId: order.id, rating: rating),
    );

    await result.fold<Future<void>>(
      (failure) async => emit(state.copyWith(
        rating: 0,
        ratingStatus: RatingStatus.failed,
        errorMessage: failure.message,
      )),
      (_) async {
        emit(state.copyWith(ratingStatus: RatingStatus.succeeded));
        await _loadOrder(order.id);
      },
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
