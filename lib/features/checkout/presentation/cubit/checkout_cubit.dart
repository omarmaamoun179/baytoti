import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/checkout.dart';
import '../../domain/usecases/checkout_usecases.dart';
import 'checkout_state.dart';

class CheckoutCubit extends BaseCubit<CheckoutState> {
  final GetCheckoutAddressesUseCase _getAddresses;
  final PlaceOrderUseCase _placeOrder;

  CheckoutCubit(this._getAddresses, this._placeOrder)
      : super(const CheckoutState());

  Future<void> load() => _read();

  Future<void> addressAdded() => _read(
        known: {for (final a in state.addresses ?? const []) a.id},
      );

  Future<void> _read({Set<String>? known}) async {
    emit(state.copyWith(
      status: state.addresses == null ? CheckoutStatus.loading : state.status,
    ));

    final result = await _getAddresses(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.addresses == null
            ? CheckoutStatus.error
            : CheckoutStatus.loaded,
        errorMessage: failure.message,
      )),
      (addresses) {
        final added = known == null
            ? null
            : addresses.where((a) => !known.contains(a.id)).firstOrNull;
        final picked = added ??
            addresses.byId(state.addressId) ??
            addresses.preferred;
        emit(state.copyWith(
          status: CheckoutStatus.loaded,
          addresses: addresses,
          addressId: picked?.id,
          clearAddress: picked == null,
        ));
      },
    );
  }

  void selectAddress(String id) {
    if (state.isBusy || state.addresses?.byId(id) == null) return;
    emit(state.copyWith(addressId: id));
  }

  Future<void> placeOrder() async {
    final address = state.address;
    if (!state.canPlace || address == null) return;

    emit(state.copyWith(isPlacing: true));

    final result = await _placeOrder(PlaceOrderParams(addressId: address.id));

    result.fold(
      (failure) => emit(state.copyWith(
        isPlacing: false,
        errorMessage: failure.message,
      )),
      (orders) => emit(state.copyWith(isPlacing: false, placedOrders: orders)),
    );
  }
}
