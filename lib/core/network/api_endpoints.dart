import '../utils/constants.dart';

class ApiEndPoint {
  ApiEndPoint._();

  static String _url(String path) => '$baseUrl$path';

  static String get register => _url('auth/register');
  static String get login => _url('auth/login');
  static String get requestOtp => _url('auth/request-otp');
  static String get verifyOtp => _url('auth/verify-otp');
  static String get resendOtp => requestOtp;
  static String get refresh => _url('auth/refresh');
  static String get logout => _url('auth/logout');
  static String get me => _url('auth/me');
  static String get updateProfile => _url('auth/profile');

  static String get countries => _url('countries');
  static String country(String id) => _url('countries/$id');
  static String countryGovernorates(String countryId) =>
      _url('countries/$countryId/governorates');
  static String get locationContext => _url('location/context');

  static String get categories => _url('categories');

  static String get home => _url('home');
  static String get explore => _url('explore');
  static String get search => _url('search');
  static String get searchSuggestions => _url('search/suggestions');

  static String product(String id) => _url('products/$id');
  static String productReviews(String id) => _url('products/$id/reviews');

  static String get stores => _url('stores');
  static String family(String id) => _url('stores/$id');
  static String familyProducts(String id) => _url('stores/$id/products');
  static String familyFollow(String id) => _url('stores/$id/follow');

  static String get favourites => _url('wishlist');
  static String favourite(String productId) => _url('wishlist/$productId');
  static String get following => _url('following');

  static String get cart => _url('cart');
  static String get cartItems => _url('cart/items');
  static String cartItem(String id) => _url('cart/items/$id');
  static String get cartCoupon => _url('cart/coupon');

  static String get checkoutOptions => _url('checkout/options');
  static String get checkout => _url('orders/checkout');
  static String get addresses => _url('addresses');

  static String get orders => _url('orders');
  static String order(String id) => _url('orders/$id');
  static String orderRating(String id) => _url('orders/$id/rating');
  static String cancelOrder(String id) => _url('orders/$id/cancel');

  static String get notifications => _url('notifications');
  static String get markNotificationsRead => _url('notifications/read');

  static String get devices => _url('devices');
}
