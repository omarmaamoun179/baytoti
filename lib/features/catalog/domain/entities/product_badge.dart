enum ProductBadge {
  bestSeller('best_seller', 'badge_best_seller'),
  newArrival('new', 'badge_new'),
  trending('trending', 'badge_trending'),
  featured('featured', 'badge_featured');

  final String wire;
  final String labelKey;

  const ProductBadge(this.wire, this.labelKey);

  static ProductBadge? fromWire(Object? value) {
    for (final badge in values) {
      if (badge.wire == value) return badge;
    }
    return null;
  }
}
