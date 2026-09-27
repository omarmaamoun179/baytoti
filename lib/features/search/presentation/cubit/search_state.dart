import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/search_query.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final SearchStatus status;
  final SearchQuery query;
  final Paged<ProductSummary>? results;
  final List<Category> categories;
  final bool isLoadingMore;
  final String? errorMessage;

  const SearchState({
    this.status = SearchStatus.initial,
    this.query = const SearchQuery(),
    this.results,
    this.categories = const [],
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isRefreshing => status == SearchStatus.loading && results != null;

  String? get categoryName {
    final slug = query.categorySlug;
    if (slug == null) return null;
    return categories.where((c) => c.slug == slug).firstOrNull?.name;
  }

  SearchState copyWith({
    SearchStatus? status,
    SearchQuery? query,
    Paged<ProductSummary>? results,
    bool clearResults = false,
    List<Category>? categories,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: clearResults ? null : results ?? this.results,
      categories: categories ?? this.categories,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, query, results, categories, isLoadingMore, errorMessage];
}
