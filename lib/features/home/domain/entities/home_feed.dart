import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/domain/entities/family_ref.dart';
import '../../../catalog/domain/entities/product_summary.dart';

class HomeBanner extends Equatable {
  final String id;
  final String kind;
  final String kicker;
  final String title;
  final String subtitle;
  final String? dateDisplay;
  final String? actionLabel;

  const HomeBanner({
    required this.id,
    required this.kind,
    required this.kicker,
    required this.title,
    required this.subtitle,
    this.dateDisplay,
    this.actionLabel,
  });

  @override
  List<Object?> get props =>
      [id, kind, kicker, title, subtitle, dateDisplay, actionLabel];
}

class HomeFeed extends Equatable {
  final HomeBanner? banner;
  final List<Category> categories;
  final List<FamilyRef> featuredFamilies;
  final List<ProductSummary> bestSellers;

  const HomeFeed({
    this.banner,
    this.categories = const [],
    this.featuredFamilies = const [],
    this.bestSellers = const [],
  });

  @override
  List<Object?> get props =>
      [banner, categories, featuredFamilies, bestSellers];
}
