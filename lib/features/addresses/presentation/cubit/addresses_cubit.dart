import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/addresses_usecases.dart';

enum AddressesStatus { loading, loaded, error }

class AddressesState extends Equatable {
  final AddressesStatus status;
  final List<Address> addresses;
  final String? busyId;
  final String? errorMessage;

  const AddressesState({
    this.status = AddressesStatus.loading,
    this.addresses = const [],
    this.busyId,
    this.errorMessage,
  });

  bool get isLoaded => status == AddressesStatus.loaded;

  bool get isEmpty => isLoaded && addresses.isEmpty;

  bool isBusy(String id) => busyId == id;

  AddressesState copyWith({
    AddressesStatus? status,
    List<Address>? addresses,
    String? Function()? busyId,
    String? errorMessage,
  }) {
    return AddressesState(
      status: status ?? this.status,
      addresses: addresses ?? this.addresses,
      busyId: busyId == null ? this.busyId : busyId(),
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, addresses, busyId, errorMessage];
}

class AddressesCubit extends BaseCubit<AddressesState> {
  final GetAddressesUseCase _getAddresses;
  final DeleteAddressUseCase _deleteAddress;
  final SetDefaultAddressUseCase _setDefault;

  int _generation = 0;

  AddressesCubit(this._getAddresses, this._deleteAddress, this._setDefault)
      : super(const AddressesState());

  Future<void> load() async {
    final generation = ++_generation;
    if (!state.isLoaded) {
      emit(state.copyWith(status: AddressesStatus.loading));
    }

    final result = await _getAddresses(NoParams());
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.isLoaded ? AddressesStatus.loaded : AddressesStatus.error,
        busyId: () => null,
        errorMessage: failure.message,
      )),
      (addresses) => emit(state.copyWith(
        status: AddressesStatus.loaded,
        addresses: addresses,
        busyId: () => null,
      )),
    );
  }

  Future<void> delete(String id) => _mutate(id, () => _deleteAddress(id));

  Future<void> makeDefault(String id) => _mutate(id, () => _setDefault(id));

  Future<void> _mutate(
    String id,
    Future<Either<Failure, Unit>> Function() call,
  ) async {
    if (!state.isLoaded || state.busyId != null) return;
    emit(state.copyWith(busyId: () => id));

    final result = await call();

    await result.fold(
      (failure) async => emit(state.copyWith(
        busyId: () => null,
        errorMessage: failure.message,
      )),
      (_) => load(),
    );
  }
}
