import '../utils/constants.dart';

class ApiEndPoint {
  ApiEndPoint._();

  static String _url(String path) => '$baseUrl$path';

  static String get register => _url('auth/register');
  static String get login => _url('auth/login');
  static String get requestOtp => _url('auth/request-otp');
  static String get verifyOtp => _url('auth/verify-otp');
  static String get resendOtp => requestOtp;
  static String get logout => _url('auth/logout');
  static String get me => _url('auth/me');
  static String get updateProfile => _url('auth/profile');

  static String get countries => _url('countries');
  static String country(String id) => _url('countries/$id');
  static String countryGovernorates(String countryId) =>
      _url('countries/$countryId/governorates');
  static String get locationContext => _url('location/context');

  static String get home => _url('home');

  static String get categories => _url('categories');
  static String get activeCategories => _url('categories/active');

  static String get products => _url('products');
  static String product(String slug) => _url('products/$slug');
  static String productReviews(String productId) =>
      _url('products/$productId/reviews');
  static String get reviews => _url('reviews');

  static String get stores => _url('stores');
  static String store(String slug) => _url('stores/$slug');

  static String get wishlist => _url('wishlist');
  static String get wishlistItems => _url('wishlist/items');
  static String wishlistItem(String id) => _url('wishlist/items/$id');

  static String get cart => _url('cart');
  static String get cartItems => _url('cart/items');
  static String cartItem(String id) => _url('cart/items/$id');

  static String get addresses => _url('addresses');
  static String address(String id) => _url('addresses/$id');
  static String defaultAddress(String id) => _url('addresses/$id/default');

  static String get orders => _url('orders');
  static String get checkout => _url('orders/checkout');
  static String order(String id) => _url('orders/$id');
  static String cancelOrder(String id) => _url('orders/$id/cancel');

  static String createPayment(String id) => _url('payments/$id/create');
  static String verifyPayment(String id) => _url('payments/$id/verify');

  static String get notifications => _url('notifications');
  static String get unreadNotificationCount =>
      _url('notifications/unread-count');
  static String get markNotificationsRead => _url('notifications/read-all');
  static String markNotificationRead(String id) =>
      _url('notifications/$id/read');
}
