import 'package:equatable/equatable.dart';

import '../../domain/entities/search_query.dart';
import '../../domain/entities/search_results.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final SearchQuery query;
  final SearchResults? results;
  final bool isLoadingMore;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = const SearchQuery(),
    this.results,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isRefreshing => status == SearchStatus.loading && results != null;

  SearchFacets get facets => results?.facets ?? const SearchFacets();

  SearchState copyWith({
    SearchStatus? status,
    SearchQuery? query,
    SearchResults? results,
    bool clearResults = false,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: clearResults ? null : results ?? this.results,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, query, results, isLoadingMore, errorMessage];
}
