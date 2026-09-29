import 'package:equatable/equatable.dart';

import '../../domain/entities/product_detail.dart';

enum ProductStatus { initial, loading, loaded, error }

class ProductState extends Equatable {
  final ProductStatus status;
  final ProductDetail? product;
  final List<Review> reviews;
  final Review? myReview;
  final bool reviewsLoaded;
  final bool isLoadingReviews;
  final int quantity;
  final bool isSavingFavourite;
  final String? errorMessage;

  const ProductState({
    this.status = ProductStatus.initial,
    this.product,
    this.reviews = const [],
    this.myReview,
    this.reviewsLoaded = false,
    this.isLoadingReviews = false,
    this.quantity = 1,
    this.isSavingFavourite = false,
    this.errorMessage,
  });

  bool get canOrder => product?.canOrder ?? false;

  bool get canDecrement => canOrder && quantity > 1;

  bool get canIncrement =>
      canOrder && quantity < (product?.maxQuantity ?? 0);

  ProductState copyWith({
    ProductStatus? status,
    ProductDetail? product,
    List<Review>? reviews,
    Review? myReview,
    bool? reviewsLoaded,
    bool? isLoadingReviews,
    int? quantity,
    bool? isSavingFavourite,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      product: product ?? this.product,
      reviews: reviews ?? this.reviews,
      myReview: myReview ?? this.myReview,
      reviewsLoaded: reviewsLoaded ?? this.reviewsLoaded,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
      quantity: quantity ?? this.quantity,
      isSavingFavourite: isSavingFavourite ?? this.isSavingFavourite,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        product,
        reviews,
        myReview,
        reviewsLoaded,
        isLoadingReviews,
        quantity,
        isSavingFavourite,
        errorMessage,
      ];
}
