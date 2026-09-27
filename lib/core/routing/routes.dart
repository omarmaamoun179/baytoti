class AppRoutes {
  AppRoutes._();

  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String otp = '/otp';

  static const String home = '/home';
  static const String explore = '/explore';
  static const String search = '/search';
  static const String cart = '/cart';
  static const String profile = '/profile';

  static const List<String> tabs = [home, explore, search, cart, profile];

  static const String productSegment = 'products';
  static const String familySegment = 'families';
  static const String orderSegment = 'orders';
  static const String notificationsSegment = 'notifications';
  static const String checkoutSegment = 'checkout';

  static const String fromQuery = 'from';
  static const String tabQuery = 'tab';
  static const String signupTab = 'signup';
  static const String searchQuery = 'q';
  static const String categoryQuery = 'category';

  static String authFor({String? from, bool signup = false}) => Uri(
        path: auth,
        queryParameters: {
          if (signup) tabQuery: signupTab,
          fromQuery: ?from,
        },
      ).toString();

  static String searchFor({String? query, String? categoryId}) => Uri(
        path: search,
        queryParameters: {
          if (query != null && query.isNotEmpty) searchQuery: query,
          categoryQuery: ?categoryId,
        },
      ).toString();
}
