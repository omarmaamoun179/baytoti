import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/failure.dart';
import '../../../auth/domain/entities/customer.dart';
import '../../domain/entities/profile_update.dart';
import '../../domain/usecases/profile_usecases.dart';

enum EditProfileStatus { editing, saving, saved }

class EditProfileState extends Equatable {
  final EditProfileStatus status;
  final Map<String, String> fieldErrors;
  final Customer? saved;
  final String? errorMessage;

  const EditProfileState({
    this.status = EditProfileStatus.editing,
    this.fieldErrors = const {},
    this.saved,
    this.errorMessage,
  });

  bool get isSaving => status == EditProfileStatus.saving;

  bool get isSaved => status == EditProfileStatus.saved;

  EditProfileState copyWith({
    EditProfileStatus? status,
    Map<String, String>? fieldErrors,
    Customer? saved,
    String? errorMessage,
  }) {
    return EditProfileState(
      status: status ?? this.status,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, fieldErrors, saved, errorMessage];
}

class EditProfileCubit extends BaseCubit<EditProfileState> {
  final UpdateProfileUseCase _updateProfile;

  EditProfileCubit(this._updateProfile) : super(const EditProfileState());

  Future<void> save(ProfileUpdate update) async {
    if (state.isSaving || state.isSaved) return;
    emit(const EditProfileState(status: EditProfileStatus.saving));

    final result = await _updateProfile(update);

    result.fold(
      (failure) => emit(EditProfileState(
        fieldErrors:
            failure is ValidationFailure ? failure.fieldErrors : const {},
        errorMessage: failure.message,
      )),
      (customer) => emit(EditProfileState(
        status: EditProfileStatus.saved,
        saved: customer,
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
