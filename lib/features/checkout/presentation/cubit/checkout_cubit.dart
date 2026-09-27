import 'dart:math';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/usecases/checkout_usecases.dart';
import 'checkout_state.dart';

class CheckoutCubit extends BaseCubit<CheckoutState> {
  final GetCheckoutOptionsUseCase _getOptions;
  final PlaceOrderUseCase _placeOrder;
  final String idempotencyKey;

  CheckoutCubit(
    this._getOptions,
    this._placeOrder, {
    String? idempotencyKey,
  })  : idempotencyKey = idempotencyKey ?? newIdempotencyKey(),
        super(const CheckoutState());

  static String newIdempotencyKey() {
    final random = Random.secure();
    String part() => random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return '${DateTime.now().microsecondsSinceEpoch}-${part()}${part()}';
  }

  Future<void> load() async {
    emit(state.copyWith(
      status: state.options == null ? CheckoutStatus.loading : state.status,
    ));

    final result = await _getOptions(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.options == null
            ? CheckoutStatus.error
            : CheckoutStatus.loaded,
        errorMessage: failure.message,
      )),
      (options) => emit(state.copyWith(
        status: CheckoutStatus.loaded,
        options: options,
        addressId: (options.address(state.addressId) ?? options.defaultAddress)
            ?.id,
        fulfilmentId:
            (options.method(state.fulfilmentId) ?? options.firstAvailableMethod)
                ?.id,
        paymentId:
            (options.payment(state.paymentId) ?? options.firstAvailablePayment)
                ?.id,
      )),
    );
  }

  void selectAddress(String id) {
    if (state.isBusy || state.options?.address(id) == null) return;
    emit(state.copyWith(addressId: id));
  }

  void selectFulfilment(String id) {
    if (state.isBusy || state.options?.method(id) == null) return;
    emit(state.copyWith(fulfilmentId: id));
  }

  void selectPayment(String id) {
    if (state.isBusy || state.options?.payment(id) == null) return;
    emit(state.copyWith(paymentId: id));
  }

  Future<void> placeOrder(String cartId) async {
    final address = state.address;
    final fulfilment = state.fulfilment;
    final payment = state.payment;
    if (!state.canPlace ||
        address == null ||
        fulfilment == null ||
        payment == null) {
      return;
    }

    emit(state.copyWith(isPlacing: true));

    final result = await _placeOrder(PlaceOrderParams(
      cartId: cartId,
      addressId: address.id,
      fulfilmentMethod: fulfilment.id,
      paymentMethod: payment.id,
      idempotencyKey: idempotencyKey,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        isPlacing: false,
        errorMessage: failure.message,
      )),
      (order) => emit(state.copyWith(isPlacing: false, placedOrder: order)),
    );
  }
}
