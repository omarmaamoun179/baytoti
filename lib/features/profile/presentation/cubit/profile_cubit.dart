import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/usecases/profile_usecases.dart';
import 'profile_state.dart';

class ProfileCubit extends BaseCubit<ProfileState> {
  final GetProfileUseCase _getProfile;

  Future<void>? _reading;

  ProfileCubit(this._getProfile) : super(const ProfileState());

  Future<void> load() =>
      _reading ??= _read().whenComplete(() => _reading = null);

  Future<void> _read() async {
    final hadCustomer = state.customer != null;
    emit(state.copyWith(status: hadCustomer ? null : ProfileStatus.loading));

    final result = await _getProfile(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: hadCustomer ? null : ProfileStatus.error,
        errorMessage: failure.message,
      )),
      (customer) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        customer: customer,
      )),
    );
  }
}
