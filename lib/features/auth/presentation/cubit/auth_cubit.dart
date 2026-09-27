import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/app/session_notifier.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/customer.dart';
import '../../domain/usecases/auth_usecases.dart';
import 'auth_state.dart';

class AuthCubit extends BaseCubit<AuthState> {
  final RestoreSessionUseCase _restoreSession;
  final SignOutUseCase _signOut;
  final ClearSessionUseCase _clearSession;
  final SessionNotifier _session;

  AuthCubit(
    this._restoreSession,
    this._signOut,
    this._clearSession,
    this._session,
  ) : super(const AuthState());

  Future<void> restoreSession() async {
    final result = await _restoreSession(NoParams());

    result.fold(
      (_) => _becomeGuest(),
      (customer) =>
          customer == null ? _becomeGuest() : completeSignIn(customer),
    );
  }

  void completeSignIn(Customer customer) {
    emit(AuthState(status: AuthStatus.signedIn, customer: customer));
    _session.signedIn();
  }

  void updateCustomer(Customer customer) {
    if (!state.isSignedIn) return;
    emit(AuthState(status: AuthStatus.signedIn, customer: customer));
  }

  Future<void> signOut() async {
    await _signOut(NoParams());
    _becomeGuest();
  }

  Future<void> sessionExpired() async {
    await _clearSession(NoParams());
    _becomeGuest();
  }

  void _becomeGuest() {
    emit(const AuthState(status: AuthStatus.guest));
    _session.signedOut();
  }
}
