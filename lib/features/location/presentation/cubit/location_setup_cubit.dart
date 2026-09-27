import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/location_usecases.dart';

enum LocationSetupStatus { loading, ready, failed, saving, saved }

class LocationSetupState extends Equatable {
  final LocationSetupStatus status;
  final List<Country> countries;
  final List<Governorate> governorates;
  final Country? country;
  final Governorate? governorate;
  final bool loadingGovernorates;
  final LocationContext? saved;
  final String? errorMessage;

  const LocationSetupState({
    this.status = LocationSetupStatus.loading,
    this.countries = const [],
    this.governorates = const [],
    this.country,
    this.governorate,
    this.loadingGovernorates = false,
    this.saved,
    this.errorMessage,
  });

  bool get canSave =>
      country != null &&
      governorate != null &&
      status != LocationSetupStatus.saving;

  LocationSetupState copyWith({
    LocationSetupStatus? status,
    List<Country>? countries,
    List<Governorate>? governorates,
    Country? country,
    Governorate? Function()? governorate,
    bool? loadingGovernorates,
    LocationContext? saved,
    String? errorMessage,
  }) {
    return LocationSetupState(
      status: status ?? this.status,
      countries: countries ?? this.countries,
      governorates: governorates ?? this.governorates,
      country: country ?? this.country,
      governorate: governorate == null ? this.governorate : governorate(),
      loadingGovernorates: loadingGovernorates ?? this.loadingGovernorates,
      saved: saved ?? this.saved,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        countries,
        governorates,
        country,
        governorate,
        loadingGovernorates,
        saved,
        errorMessage,
      ];
}

class LocationSetupCubit extends BaseCubit<LocationSetupState> {
  final GetCountriesUseCase _getCountries;
  final GetGovernoratesUseCase _getGovernorates;
  final SetManualLocationUseCase _setManual;

  LocationSetupCubit(this._getCountries, this._getGovernorates, this._setManual)
      : super(const LocationSetupState());

  Future<void> load() async {
    emit(const LocationSetupState());
    final result = await _getCountries(NoParams());

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: LocationSetupStatus.failed,
        errorMessage: failure.message,
      )),
      (countries) async {
        emit(state.copyWith(
          status: LocationSetupStatus.ready,
          countries: countries,
        ));
        if (countries.length == 1) await selectCountry(countries.single);
      },
    );
  }

  Future<void> selectCountry(Country country) async {
    if (country == state.country && state.governorates.isNotEmpty) return;
    emit(state.copyWith(
      country: country,
      governorate: () => null,
      governorates: const [],
      loadingGovernorates: true,
    ));

    final result = await _getGovernorates(country.id);
    if (state.country != country) return;

    result.fold(
      (failure) => emit(state.copyWith(
        loadingGovernorates: false,
        errorMessage: failure.message,
      )),
      (governorates) => emit(state.copyWith(
        governorates: governorates,
        loadingGovernorates: false,
      )),
    );
  }

  void selectGovernorate(Governorate governorate) =>
      emit(state.copyWith(governorate: () => governorate));

  Future<void> save() async {
    final country = state.country;
    final governorate = state.governorate;
    if (!state.canSave || country == null || governorate == null) return;
    emit(state.copyWith(status: LocationSetupStatus.saving));

    final result = await _setManual(ManualLocationParams(
      country: country,
      governorate: governorate,
    ));

    result.fold(
      (failure) => emit(state.copyWith(
        status: LocationSetupStatus.ready,
        errorMessage: failure.message,
      )),
      (context) => emit(state.copyWith(
        status: LocationSetupStatus.saved,
        saved: context,
      )),
    );
  }
}
