import 'package:equatable/equatable.dart';

import '../../../../core/domain/paged.dart';
import '../../../catalog/domain/entities/product_summary.dart';
import '../../domain/entities/family_profile.dart';

enum FamilyStatus { initial, loading, loaded, error }

class FamilyState extends Equatable {
  final FamilyStatus status;
  final FamilyProfile? family;
  final Paged<ProductSummary> products;
  final bool isLoadingMore;
  final String? errorMessage;

  const FamilyState({
    this.status = FamilyStatus.initial,
    this.family,
    this.products = const Paged<ProductSummary>(),
    this.isLoadingMore = false,
    this.errorMessage,
  });

  bool get canLoadMore =>
      status == FamilyStatus.loaded && !isLoadingMore && products.hasMore;

  int? get productCount => family?.productCount ?? products.total;

  FamilyState copyWith({
    FamilyStatus? status,
    FamilyProfile? family,
    Paged<ProductSummary>? products,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return FamilyState(
      status: status ?? this.status,
      family: family ?? this.family,
      products: products ?? this.products,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [status, family, products, isLoadingMore, errorMessage];
}
