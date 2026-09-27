import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/explore_feed.dart';

class RisingProductModel extends RisingProduct {
  const RisingProductModel({
    required super.rank,
    required super.product,
    required super.growth,
  });

  factory RisingProductModel.fromJson(Map<String, dynamic> json) =>
      RisingProductModel(
        rank: jsonInt(json['rank']) ?? 0,
        product: ProductSummaryModel.fromJson(jsonMap(json['product'])),
        growth: json['growth_display'] as String? ?? '',
      );
}

class ExploreFeedModel extends ExploreFeed {
  const ExploreFeedModel({
    super.hashtags,
    super.rising,
    super.mostViewed,
    super.nextCursor,
  });

  factory ExploreFeedModel.fromJson(Map<String, dynamic> json) =>
      ExploreFeedModel(
        hashtags: stringList(json['hashtags']),
        rising: [
          for (final item in jsonList(json['rising']))
            RisingProductModel.fromJson(item),
        ],
        mostViewed: ProductSummaryModel.listFrom(json['most_viewed']),
        nextCursor: json['next_cursor'] as String?,
      );
}
