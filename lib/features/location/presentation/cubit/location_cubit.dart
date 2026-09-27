import 'dart:async';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/app/session_notifier.dart';
import '../../../../core/domain/usecase.dart';
import '../../../../core/utils/market.dart';
import '../../../../core/utils/money.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/location_usecases.dart';

class LocationCubit extends BaseCubit<LocationContext> {
  final GetLocationContextUseCase _getContext;
  final ForgetLocationUseCase _forget;
  final SessionNotifier _session;

  bool? _wasSignedIn;

  LocationCubit(this._getContext, this._forget, this._session)
      : super(LocationContext.none) {
    _session.addListener(_onSessionChanged);
    _onSessionChanged();
  }

  void _onSessionChanged() {
    if (!_session.isResolved) return;
    final signedIn = _session.isAuthenticated;
    if (signedIn == _wasSignedIn) return;
    _wasSignedIn = signedIn;

    signedIn ? unawaited(refresh()) : unawaited(_signedOut());
  }

  Future<void> refresh() async {
    final result = await _getContext(NoParams());

    result.fold(
      (_) => _session.locationKnown(false),
      adopt,
    );
  }

  void adopt(LocationContext context) {
    Money.market = Market.fromIso(context.countryCode);
    emit(context);
    _session.locationKnown(context.isSet);
  }

  Future<void> _signedOut() async {
    await _forget(NoParams());
    Money.market = Market.fallback;
    emit(LocationContext.none);
  }

  @override
  Future<void> close() {
    _session.removeListener(_onSessionChanged);
    return super.close();
  }
}
