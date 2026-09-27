import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../domain/entities/home_feed.dart';

class HomeBannerModel extends HomeBanner {
  const HomeBannerModel({
    required super.id,
    required super.kind,
    required super.kicker,
    required super.title,
    required super.subtitle,
    super.dateDisplay,
    super.actionLabel,
  });

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) =>
      HomeBannerModel(
        id: json['id'] as String,
        kind: json['kind'] as String? ?? '',
        kicker: json['kicker'] as String? ?? '',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        dateDisplay: json['date_display'] as String?,
        actionLabel: jsonMapOrNull(json['action'])?['label'] as String?,
      );
}

class HomeFeedModel extends HomeFeed {
  const HomeFeedModel({
    super.banner,
    super.categories,
    super.featuredFamilies,
    super.bestSellers,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) {
    final banner = jsonMapOrNull(json['banner']);

    return HomeFeedModel(
      banner: banner == null ? null : HomeBannerModel.fromJson(banner),
      categories: [
        for (final item in jsonList(json['categories']))
          CategoryModel.fromJson(item),
      ],
      featuredFamilies: [
        for (final item in jsonList(json['featured_families']))
          FamilyRefModel.fromJson(item),
      ],
      bestSellers: ProductSummaryModel.listFrom(json['best_sellers']),
    );
  }
}
