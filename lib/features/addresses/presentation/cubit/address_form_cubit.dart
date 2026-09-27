import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../domain/entities/address.dart';
import '../../domain/usecases/addresses_usecases.dart';

enum AddressFormStatus { editing, saving, saved }

class AddressFormState extends Equatable {
  final AddressFormStatus status;
  final Map<String, String> fieldErrors;
  final Address? saved;
  final String? errorMessage;

  const AddressFormState({
    this.status = AddressFormStatus.editing,
    this.fieldErrors = const {},
    this.saved,
    this.errorMessage,
  });

  bool get isSaving => status == AddressFormStatus.saving;

  bool get isSaved => status == AddressFormStatus.saved;

  AddressFormState copyWith({
    AddressFormStatus? status,
    Map<String, String>? fieldErrors,
    Address? saved,
    String? errorMessage,
  }) {
    return AddressFormState(
      status: status ?? this.status,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, fieldErrors, saved, errorMessage];
}

class AddressFormCubit extends BaseCubit<AddressFormState> {
  final CreateAddressUseCase _createAddress;
  final UpdateAddressUseCase _updateAddress;

  AddressFormCubit(this._createAddress, this._updateAddress)
      : super(const AddressFormState());

  Future<void> save(AddressParams params, {String? id}) async {
    if (state.isSaving || state.isSaved) return;
    emit(const AddressFormState(status: AddressFormStatus.saving));

    final result = id == null
        ? await _createAddress(params)
        : await _updateAddress(UpdateAddressParams(id: id, address: params));

    result.fold(
      (failure) => emit(AddressFormState(
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
        errorMessage: failure.message,
      )),
      (address) => emit(AddressFormState(
        status: AddressFormStatus.saved,
        saved: address,
      )),
    );
  }

  void clearFieldError(String field) {
    if (!state.fieldErrors.containsKey(field)) return;
    emit(state.copyWith(
      fieldErrors: {...state.fieldErrors}..remove(field),
    ));
  }
}
