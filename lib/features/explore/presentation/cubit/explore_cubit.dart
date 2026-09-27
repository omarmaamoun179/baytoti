import '../../../../core/abstract/base_cubit.dart';
import '../../domain/entities/explore_feed.dart';
import '../../domain/usecases/explore_usecases.dart';
import 'explore_state.dart';

class ExploreCubit extends BaseCubit<ExploreState> {
  final GetExploreUseCase _getExplore;

  int _generation = 0;

  ExploreCubit(this._getExplore) : super(const ExploreState());

  Future<void> load([ExploreTab? tab]) async {
    final target = tab ?? state.tab;
    final generation = ++_generation;
    emit(state.copyWith(
      status: ExploreStatus.loading,
      tab: target,
      isLoadingMore: false,
    ));

    final result = await _getExplore(ExploreParams(tab: target));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.feed == null
          ? state.copyWith(
              status: ExploreStatus.error,
              errorMessage: failure.message,
            )
          : state.copyWith(
              status: ExploreStatus.loaded,
              tab: state.feedTab,
              errorMessage: failure.message,
            )),
      (feed) => emit(state.copyWith(
        status: ExploreStatus.loaded,
        feed: feed,
        feedTab: target,
      )),
    );
  }

  void selectTab(ExploreTab tab) {
    if (tab == state.tab && state.status != ExploreStatus.error) return;
    load(tab);
  }

  Future<void> loadMore() async {
    final feed = state.feed;
    final feedTab = state.feedTab;
    if (feed == null ||
        feedTab == null ||
        !feed.hasMore ||
        state.isLoadingMore ||
        state.status != ExploreStatus.loaded) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _getExplore(
      ExploreParams(tab: feedTab, page: feed.nextPage),
    );
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (next) => emit(state.copyWith(
        feed: feed.append(next),
        isLoadingMore: false,
      )),
    );
  }
}
