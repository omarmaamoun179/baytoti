enum ExploreTab {
  newest('explore_tab_new', sort: 'newest'),
  featured('explore_tab_featured', featuredOnly: true),
  priceLow('explore_tab_price_low', sort: 'price_asc');

  final String labelKey;
  final String? sort;
  final bool featuredOnly;

  const ExploreTab(this.labelKey, {this.sort, this.featuredOnly = false});

  static const ExploreTab initial = newest;
}
