import 'package:equatable/equatable.dart';

import '../../../../core/utils/constants.dart';

enum SearchSort {
  newest('newest', 'search_sort_newest', 'search_sort_option_newest'),
  priceAsc(
    'price_asc',
    'search_sort_price_asc',
    'search_sort_option_price_asc',
  ),
  priceDesc(
    'price_desc',
    'search_sort_price_desc',
    'search_sort_option_price_desc',
  );

  final String wire;
  final String labelKey;
  final String optionKey;

  const SearchSort(this.wire, this.labelKey, this.optionKey);

  static const SearchSort initial = newest;

  static const List<SearchSort> byPrice = [priceAsc, priceDesc];

  bool get isByPrice => byPrice.contains(this);
}

class SearchQuery extends Equatable {
  final String text;
  final String? categorySlug;
  final SearchSort sort;
  final int? page;
  final int limit;

  const SearchQuery({
    this.text = '',
    this.categorySlug,
    this.sort = SearchSort.initial,
    this.page,
    this.limit = defaultPageSize,
  });

  bool get hasFilters => categorySlug != null || sort.isByPrice;

  SearchQuery _with({
    String? text,
    String? Function()? categorySlug,
    SearchSort? sort,
    int? Function()? page,
  }) =>
      SearchQuery(
        text: text ?? this.text,
        categorySlug: categorySlug == null ? this.categorySlug : categorySlug(),
        sort: sort ?? this.sort,
        page: page == null ? this.page : page(),
        limit: limit,
      );

  SearchQuery withText(String value) => _with(text: value.trim());

  SearchQuery withCategory(String? slug) => _with(
        categorySlug: () => slug == null || slug.trim().isEmpty
            ? null
            : slug.trim(),
      );

  SearchQuery withSort(SearchSort value) => _with(sort: value);

  SearchQuery at(int? value) => _with(page: () => value);

  SearchQuery cleared() => SearchQuery(
        text: text,
        sort: sort.isByPrice ? SearchSort.initial : sort,
        limit: limit,
      );

  Map<String, dynamic> toQueryParameters() => {
        if (text.isNotEmpty) 'search': text,
        'category': ?categorySlug,
        'sort': sort.wire,
        'page': ?page,
        'per_page': limit,
      };

  @override
  List<Object?> get props => [text, categorySlug, sort, page, limit];
}
