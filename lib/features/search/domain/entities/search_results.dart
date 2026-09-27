import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';

class SearchFacet extends Equatable {
  final String value;
  final String label;
  final int count;

  const SearchFacet({
    required this.value,
    required this.label,
    required this.count,
  });

  @override
  List<Object?> get props => [value, label, count];
}

class PriceRange extends Equatable {
  final int minFils;
  final int maxFils;

  const PriceRange({required this.minFils, required this.maxFils});

  @override
  List<Object?> get props => [minFils, maxFils];
}

class SearchFacets extends Equatable {
  final List<SearchFacet> categories;
  final List<SearchFacet> cities;
  final PriceRange? priceRange;

  const SearchFacets({
    this.categories = const [],
    this.cities = const [],
    this.priceRange,
  });

  String? categoryName(String? id) => _labelOf(categories, id);

  String? cityName(String? value) => _labelOf(cities, value);

  static String? _labelOf(List<SearchFacet> facets, String? value) {
    if (value == null) return null;
    for (final facet in facets) {
      if (facet.value == value) return facet.label;
    }
    return null;
  }

  @override
  List<Object?> get props => [categories, cities, priceRange];
}

class SearchResults extends Equatable {
  final Paged<ProductSummary> page;
  final SearchFacets facets;

  const SearchResults({
    this.page = const Paged(),
    this.facets = const SearchFacets(),
  });

  List<ProductSummary> get items => page.items;

  int get total => page.total ?? page.items.length;

  bool get hasMore => page.hasMore;

  String? get nextCursor => page.nextCursor;

  SearchResults append(SearchResults next) =>
      SearchResults(page: page.append(next.page), facets: facets);

  SearchResults withFavourite(String productId, bool isFavourite) =>
      SearchResults(
        page: Paged<ProductSummary>(
          items: [
            for (final item in page.items)
              item.id == productId
                  ? item.copyWith(isFavourite: isFavourite)
                  : item,
          ],
          nextCursor: page.nextCursor,
          total: page.total,
        ),
        facets: facets,
      );

  @override
  List<Object?> get props => [page, facets];
}
