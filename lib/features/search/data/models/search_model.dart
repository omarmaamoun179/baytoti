import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/search_results.dart';

class SearchFacetsModel extends SearchFacets {
  const SearchFacetsModel({
    super.categories,
    super.cities,
    super.priceRange,
  });

  factory SearchFacetsModel.fromJson(Map<String, dynamic> json) {
    final price = jsonMapOrNull(json['price_range_fils']);

    return SearchFacetsModel(
      categories: [
        for (final item in jsonList(json['categories']))
          SearchFacet(
            value: item['id'] as String,
            label: item['name'] as String,
            count: jsonInt(item['count']) ?? 0,
          ),
      ],
      cities: [
        for (final item in jsonList(json['cities']))
          SearchFacet(
            value: item['value'] as String,
            label: item['value'] as String,
            count: jsonInt(item['count']) ?? 0,
          ),
      ],
      priceRange: price == null
          ? null
          : PriceRange(
              minFils: jsonInt(price['min']) ?? 0,
              maxFils: jsonInt(price['max']) ?? 0,
            ),
    );
  }
}

class SearchResultsModel extends SearchResults {
  const SearchResultsModel({super.page, super.facets});

  factory SearchResultsModel.fromJson(Map<String, dynamic> json) =>
      SearchResultsModel(
        page: ProductSummaryModel.pageFrom(json),
        facets: SearchFacetsModel.fromJson(jsonMap(json['facets'])),
      );
}
