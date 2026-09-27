import 'package:equatable/equatable.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/usecase.dart';
import '../../domain/entities/home_feed.dart';
import '../../domain/usecases/get_home_use_case.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final HomeFeed? feed;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.feed,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    HomeFeed? feed,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, feed, errorMessage];
}

class HomeCubit extends BaseCubit<HomeState> {
  final GetHomeUseCase _getHome;

  HomeCubit(this._getHome) : super(const HomeState());

  Future<void> load() async {
    if (state.status == HomeStatus.loading) return;
    emit(state.copyWith(
      status: state.feed == null ? HomeStatus.loading : state.status,
    ));

    final result = await _getHome(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: state.feed == null ? HomeStatus.error : HomeStatus.loaded,
        errorMessage: failure.message,
      )),
      (feed) => emit(state.copyWith(status: HomeStatus.loaded, feed: feed)),
    );
  }
}
