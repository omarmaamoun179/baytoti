import 'package:equatable/equatable.dart';

enum SearchSort {
  relevance(
    'relevance',
    'search_sort_relevance',
    'search_sort_option_relevance',
  ),
  topRated(
    'top_rated',
    'search_sort_top_rated',
    'search_sort_option_top_rated',
  ),
  priceAsc(
    'price_asc',
    'search_sort_price_asc',
    'search_sort_option_price_asc',
  ),
  priceDesc(
    'price_desc',
    'search_sort_price_desc',
    'search_sort_option_price_desc',
  ),
  newest('newest', 'search_sort_newest', 'search_sort_option_newest');

  final String wire;
  final String labelKey;
  final String optionKey;

  const SearchSort(this.wire, this.labelKey, this.optionKey);

  static const SearchSort initial = topRated;

  static const List<SearchSort> byPrice = [priceAsc, priceDesc];

  bool get isByPrice => byPrice.contains(this);
}

class SearchQuery extends Equatable {
  static const double highRating = 4.5;

  final String text;
  final String? categoryId;
  final String? city;
  final int? minPriceFils;
  final int? maxPriceFils;
  final double? minRating;
  final SearchSort sort;
  final String? cursor;
  final int? limit;

  const SearchQuery({
    this.text = '',
    this.categoryId,
    this.city,
    this.minPriceFils,
    this.maxPriceFils,
    this.minRating,
    this.sort = SearchSort.initial,
    this.cursor,
    this.limit,
  });

  bool get hasFilters =>
      categoryId != null ||
      city != null ||
      minPriceFils != null ||
      maxPriceFils != null ||
      minRating != null ||
      sort.isByPrice;

  SearchQuery _with({
    String? text,
    String? Function()? categoryId,
    String? Function()? city,
    double? Function()? minRating,
    SearchSort? sort,
    String? Function()? cursor,
  }) =>
      SearchQuery(
        text: text ?? this.text,
        categoryId: categoryId == null ? this.categoryId : categoryId(),
        city: city == null ? this.city : city(),
        minPriceFils: minPriceFils,
        maxPriceFils: maxPriceFils,
        minRating: minRating == null ? this.minRating : minRating(),
        sort: sort ?? this.sort,
        cursor: cursor == null ? this.cursor : cursor(),
        limit: limit,
      );

  SearchQuery withText(String value) => _with(text: value.trim());

  SearchQuery withCategory(String? value) => _with(categoryId: () => value);

  SearchQuery withCity(String? value) => _with(city: () => value);

  SearchQuery withMinRating(double? value) => _with(minRating: () => value);

  SearchQuery withSort(SearchSort value) => _with(sort: value);

  SearchQuery at(String? value) => _with(cursor: () => value);

  SearchQuery cleared() => SearchQuery(
        text: text,
        sort: sort.isByPrice ? SearchSort.initial : sort,
        limit: limit,
      );

  Map<String, dynamic> toQueryParameters() => {
        if (text.isNotEmpty) 'q': text,
        'category_id': ?categoryId,
        'city': ?city,
        'min_price_fils': ?minPriceFils,
        'max_price_fils': ?maxPriceFils,
        'min_rating': ?minRating,
        'sort': sort.wire,
        'cursor': ?cursor,
        'limit': ?limit,
      };

  @override
  List<Object?> get props => [
        text,
        categoryId,
        city,
        minPriceFils,
        maxPriceFils,
        minRating,
        sort,
        cursor,
        limit,
      ];
}
