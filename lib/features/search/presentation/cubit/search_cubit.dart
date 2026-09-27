import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/domain/usecases/favourite_usecases.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/usecases/search_usecases.dart';
import 'search_state.dart';

class SearchCubit extends BaseCubit<SearchState> {
  static const Duration debounce = Duration(milliseconds: 500);

  final SearchProductsUseCase _search;
  final SetFavouriteUseCase _setFavourite;

  final BehaviorSubject<String> _queries = BehaviorSubject<String>();
  late final StreamSubscription<String> _querySubscription;
  final Set<String> _favouritesInFlight = {};
  int _generation = 0;

  SearchCubit(this._search, this._setFavourite) : super(const SearchState()) {
    _querySubscription = _queries
        .debounceTime(debounce)
        .map((text) => text.trim())
        .distinct()
        .listen(_onQuery);
  }

  Future<void> load({String? query, String? categoryId}) =>
      _run(SearchQuery(categoryId: categoryId).withText(query ?? ''));

  void queryChanged(String text) => _queries.add(text);

  Future<void> submit(String text) => _apply(state.query.withText(text));

  Future<void> retry() => _run(state.query);

  Future<void> selectCategory(String? categoryId) =>
      _apply(state.query.withCategory(categoryId));

  Future<void> selectCity(String? city) => _apply(state.query.withCity(city));

  Future<void> selectPriceSort(SearchSort? sort) {
    final current = state.query.sort;
    return setSort(sort ?? (current.isByPrice ? SearchSort.initial : current));
  }

  Future<void> setSort(SearchSort sort) => _apply(state.query.withSort(sort));

  Future<void> toggleRating() => _apply(state.query.withMinRating(
        state.query.minRating == null ? SearchQuery.highRating : null,
      ));

  Future<void> clearFilters() => _apply(state.query.cleared());

  void _onQuery(String text) {
    if (text == state.query.text) return;
    _apply(state.query.withText(text));
  }

  Future<void> _apply(SearchQuery query) async {
    if (query == state.query && state.status != SearchStatus.error) return;
    await _run(query);
  }

  Future<void> _run(SearchQuery query) async {
    final generation = ++_generation;
    emit(state.copyWith(
      status: SearchStatus.loading,
      query: query,
      isLoadingMore: false,
    ));

    final result = await _search(query);
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        status: SearchStatus.error,
        clearResults: true,
        errorMessage: failure.message,
      )),
      (results) => emit(state.copyWith(
        status: SearchStatus.loaded,
        results: results,
      )),
    );
  }

  Future<void> loadMore() async {
    final results = state.results;
    if (results == null ||
        !results.hasMore ||
        state.isLoadingMore ||
        state.status != SearchStatus.loaded) {
      return;
    }

    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));

    final result = await _search(state.query.at(results.nextPage));
    if (generation != _generation) return;

    result.fold(
      (failure) => emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: failure.message,
      )),
      (next) => emit(state.copyWith(
        results: (state.results ?? results).append(next),
        isLoadingMore: false,
      )),
    );
  }

  Future<void> toggleFavourite(ProductSummary product) async {
    final id = product.id;
    if (!_favouritesInFlight.add(id)) return;

    final favourite = !product.isFavourite;
    _markFavourite(id, favourite);

    final result = await _setFavourite(
      SetFavouriteParams(productId: id, favourite: favourite),
    );
    _favouritesInFlight.remove(id);

    result.fold(
      (failure) => emit(state.copyWith(
        results: state.results?.withFavourite(id, !favourite),
        errorMessage: failure.message,
      )),
      (isFavourite) => _markFavourite(id, isFavourite),
    );
  }

  void _markFavourite(String productId, bool isFavourite) {
    final results = state.results;
    if (results == null) return;
    emit(state.copyWith(
      results: results.withFavourite(productId, isFavourite),
    ));
  }

  @override
  Future<void> close() async {
    await _querySubscription.cancel();
    await _queries.close();
    return super.close();
  }
}
