import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/usecases/get_stores_use_case.dart';

enum StoresStatus { initial, loading, loaded, error }

class StoresState extends Equatable {
  final StoresStatus status;
  final List<TrustedStore> stores;
  final String? errorMessage;

  const StoresState({
    this.status = StoresStatus.initial,
    this.stores = const [],
    this.errorMessage,
  });

  bool get isLoaded => status == StoresStatus.loaded;

  StoresState copyWith({
    StoresStatus? status,
    List<TrustedStore>? stores,
    String? errorMessage,
  }) {
    return StoresState(
      status: status ?? this.status,
      stores: stores ?? this.stores,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, stores, errorMessage];
}

class StoresCubit extends BaseCubit<StoresState> {
  final GetStoresUseCase _getStores;

  StoresCubit(this._getStores) : super(const StoresState());

  Future<void> load() async {
    if (state.status == StoresStatus.loading) return;
    final hadList = state.isLoaded;
    emit(state.copyWith(status: hadList ? null : StoresStatus.loading));

    final result = await _getStores(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: hadList ? null : StoresStatus.error,
        errorMessage: failure.message,
      )),
      (stores) => emit(state.copyWith(
        status: StoresStatus.loaded,
        stores: stores,
      )),
    );
  }
}
