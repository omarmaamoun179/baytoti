import '../../../../core/utils/json.dart';
import '../../../catalog/data/models/catalog_models.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/home_feed.dart';

String? _text(Object? value) {
  final text = jsonString(value)?.trim() ?? '';
  return text.isEmpty ? null : text;
}

class HomeTargetModel {
  HomeTargetModel._();

  static const Map<String, HomeTargetKind> _kinds = {
    'category': HomeTargetKind.category,
    'store': HomeTargetKind.family,
    'product': HomeTargetKind.product,
  };

  static HomeTarget? maybeFrom(Object? value) {
    final json = jsonMapOrNull(value);
    if (json == null) return null;

    final kind = _kinds[json['entity']];
    final id = jsonId(json['entity_id']);
    if (kind == null || id == null) return null;
    return HomeTarget(kind: kind, id: id);
  }
}

class HomeBannerModel extends HomeBanner {
  const HomeBannerModel({
    required super.id,
    required super.title,
    super.subtitle,
    super.imageUrl,
    super.actionLabel,
    super.discountLabel,
    super.target,
  });

  factory HomeBannerModel.fromJson(Map<String, dynamic> json) =>
      HomeBannerModel(
        id: jsonId(json['id']) ?? '',
        title: jsonString(json['title']) ?? '',
        subtitle: jsonString(json['subtitle']) ?? '',
        imageUrl: _text(json['mobile_image_url']) ?? _text(json['image_url']),
        actionLabel: _text(json['cta_label']),
        discountLabel: _text(json['discount_label']),
        target: HomeTargetModel.maybeFrom(json['target']),
      );

  static List<HomeBanner> listFrom(Object? value) =>
      [for (final item in jsonList(value)) HomeBannerModel.fromJson(item)];
}

class TrustedStoreModel extends TrustedStore {
  const TrustedStoreModel({
    required super.family,
    super.description,
    super.bannerUrl,
  });

  factory TrustedStoreModel.fromJson(Map<String, dynamic> json) =>
      TrustedStoreModel(
        family: FamilyRefModel.fromJson(json),
        description: jsonString(json['description'])?.trim() ?? '',
        bannerUrl: _text(json['banner_url']) ?? _text(json['banner']),
      );
}

class HomeFeedModel extends HomeFeed {
  const HomeFeedModel({
    super.banners,
    super.categories,
    super.trustedStores,
    super.featuredProducts,
    super.promotions,
  });

  factory HomeFeedModel.fromJson(Map<String, dynamic> json) => HomeFeedModel(
        banners: HomeBannerModel.listFrom(json['banners']),
        categories: CategoryModel.listFrom(json['categories']),
        trustedStores: [
          for (final item in jsonList(json['trusted_stores']))
            TrustedStoreModel.fromJson(item),
        ],
        featuredProducts: [
          for (final item in jsonList(json['featured_products']))
            _featuredProduct(item),
        ],
        promotions: HomeBannerModel.listFrom(json['promotions']),
      );

  static ProductSummary _featuredProduct(Map<String, dynamic> json) =>
      ProductSummaryModel.fromJson({
        ...json,
        'thumbnail': json['thumbnail'] ?? json['image_url'],
      });
}
