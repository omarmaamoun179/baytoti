import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/explore_tab.dart';

enum ExploreStatus { initial, loading, loaded, error }

class ExploreState extends Equatable {
  final ExploreStatus status;
  final ExploreTab tab;
  final Paged<ProductSummary>? products;
  final ExploreTab? productsTab;
  final bool isLoadingMore;
  final String? errorMessage;

  const ExploreState({
    this.status = ExploreStatus.initial,
    this.tab = ExploreTab.initial,
    this.products,
    this.productsTab,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get isSwitching => status == ExploreStatus.loading && products != null;

  ExploreState copyWith({
    ExploreStatus? status,
    ExploreTab? tab,
    Paged<ProductSummary>? products,
    ExploreTab? productsTab,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return ExploreState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      products: products ?? this.products,
      productsTab: productsTab ?? this.productsTab,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, tab, products, productsTab, isLoadingMore, errorMessage];
}
