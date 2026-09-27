import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/product_summary.dart';

enum HomeTargetKind { category, family, product }

class HomeTarget extends Equatable {
  final HomeTargetKind kind;
  final String id;

  const HomeTarget({required this.kind, required this.id});

  @override
  List<Object?> get props => [kind, id];
}

class HomeBanner extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? actionLabel;
  final String? discountLabel;
  final HomeTarget? target;

  const HomeBanner({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl,
    this.actionLabel,
    this.discountLabel,
    this.target,
  });

  @override
  List<Object?> get props =>
      [id, title, subtitle, imageUrl, actionLabel, discountLabel, target];
}

class TrustedStore extends Equatable {
  final FamilyRef family;
  final String description;
  final String? bannerUrl;

  const TrustedStore({
    required this.family,
    this.description = '',
    this.bannerUrl,
  });

  @override
  List<Object?> get props => [family, description, bannerUrl];
}

class HomeFeed extends Equatable {
  final List<HomeBanner> banners;
  final List<Category> categories;
  final List<TrustedStore> trustedStores;
  final List<ProductSummary> featuredProducts;
  final List<HomeBanner> promotions;

  const HomeFeed({
    this.banners = const [],
    this.categories = const [],
    this.trustedStores = const [],
    this.featuredProducts = const [],
    this.promotions = const [],
  });

  String? slugOf(HomeTarget? target) => switch (target) {
        null => null,
        HomeTarget(kind: HomeTargetKind.category, :final id) =>
          categories.where((c) => c.id == id).firstOrNull?.slug,
        HomeTarget(kind: HomeTargetKind.family, :final id) => trustedStores
            .where((store) => store.family.id == id)
            .firstOrNull
            ?.family
            .slug,
        HomeTarget(kind: HomeTargetKind.product, :final id) =>
          featuredProducts.where((p) => p.id == id).firstOrNull?.slug,
      };

  @override
  List<Object?> get props =>
      [banners, categories, trustedStores, featuredProducts, promotions];
}
