import 'dart:async';

import 'package:rxdart/rxdart.dart';

import '../../../../core/abstract/base_cubit.dart';
import '../../../../core/domain/paged.dart';
import '../../../../core/domain/usecase.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../../catalog/domain/usecases/favourite_usecases.dart';
import '../../domain/entities/search_query.dart';
import '../../domain/usecases/search_usecases.dart';
import 'search_state.dart';

class SearchCubit extends BaseCubit<SearchState> {
  static const Duration debounce = Duration(milliseconds: 500);

  final SearchProductsUseCase _search;
  final GetSearchCategoriesUseCase _getCategories;
  final SetFavouriteUseCase _setFavourite;

  final BehaviorSubject<String> _queries = BehaviorSubject<String>();
  late final StreamSubscription<String> _querySubscription;
  final Set<String> _favouritesInFlight = {};
  int _generation = 0;

  SearchCubit(this._search, this._getCategories, this._setFavourite)
      : super(const SearchState()) {
    _querySubscription = _queries
        .debounceTime(debounce)
        .map((text) => text.trim())
        .distinct()
        .listen(_onQuery);
  }

  Future<void> load({String? query, String? categorySlug}) => _start(
        const SearchQuery().withCategory(categorySlug).withText(query ?? ''),
      );

  void queryChanged(String text) => _queries.add(text);

  Future<void> submit(String text) => _apply(state.query.withText(text));

  Future<void> retry() => _start(state.query);

  Future<void> selectCategory(String? slug) =>
      _apply(state.query.withCategory(slug));

  Future<void> selectPriceSort(SearchSort? sort) {
    final current = state.query.sort;
    return setSort(sort ?? (current.isByPrice ? SearchSort.initial : current));
  }

  Future<void> setSort(SearchSort sort) => _apply(state.query.withSort(sort));

  Future<void> clearFilters() => _apply(state.query.cleared());

  Future<void> loadCategories() async {
    final result = await _getCategories(NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: state.status == SearchStatus.error
            ? state.errorMessage
            : failure.message,
      )),
      (categories) => emit(state.copyWith(
        categories: categories,
        errorMessage:
            state.status == SearchStatus.error ? state.errorMessage : null,
      )),
    );
  }

  Future<void> _start(SearchQuery query) async {
    await _run(query);
    if (state.status == SearchStatus.loaded && state.categories.isEmpty) {
      await loadCategories();
    }
  }

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
        results: _withFavourite(id, !favourite),
        errorMessage: failure.message,
      )),
      (isFavourite) => _markFavourite(id, isFavourite),
    );
  }

  void _markFavourite(String productId, bool isFavourite) {
    final results = _withFavourite(productId, isFavourite);
    if (results == null) return;
    emit(state.copyWith(results: results));
  }

  Paged<ProductSummary>? _withFavourite(String productId, bool isFavourite) {
    final results = state.results;
    if (results == null) return null;

    return Paged<ProductSummary>(
      items: [
        for (final item in results.items)
          item.id == productId ? item.copyWith(isFavourite: isFavourite) : item,
      ],
      currentPage: results.currentPage,
      lastPage: results.lastPage,
      total: results.total,
    );
  }

  @override
  Future<void> close() async {
    await _querySubscription.cancel();
    await _queries.close();
    return super.close();
  }
}
