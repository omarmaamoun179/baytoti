import 'package:equatable/equatable.dart';

import '../../../catalog/domain/entities/product_summary.dart';

enum ExploreTab {
  daily('daily', 'explore_tab_daily'),
  weekly('weekly', 'explore_tab_weekly'),
  fresh('new', 'explore_tab_new'),
  nearby('nearby', 'explore_tab_nearby');

  final String wire;
  final String labelKey;

  const ExploreTab(this.wire, this.labelKey);
}

class RisingProduct extends Equatable {
  final int rank;
  final ProductSummary product;
  final String growth;

  const RisingProduct({
    required this.rank,
    required this.product,
    required this.growth,
  });

  @override
  List<Object?> get props => [rank, product, growth];
}

class ExploreFeed extends Equatable {
  final List<String> hashtags;
  final List<RisingProduct> rising;
  final List<ProductSummary> mostViewed;
  final int currentPage;
  final int lastPage;

  const ExploreFeed({
    this.hashtags = const [],
    this.rising = const [],
    this.mostViewed = const [],
    this.currentPage = 1,
    this.lastPage = 1,
  });

  int get nextPage => currentPage + 1;

  bool get hasMore => currentPage < lastPage;

  bool get isEmpty => hashtags.isEmpty && rising.isEmpty && mostViewed.isEmpty;

  ExploreFeed append(ExploreFeed next) => ExploreFeed(
        hashtags: hashtags,
        rising: rising,
        mostViewed: [...mostViewed, ...next.mostViewed],
        currentPage: next.currentPage,
        lastPage: next.lastPage,
      );

  @override
  List<Object?> get props =>
      [hashtags, rising, mostViewed, currentPage, lastPage];
}
