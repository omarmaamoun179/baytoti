import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/addresses/domain/entities/address.dart';
import '../../features/addresses/presentation/pages/address_form_page.dart';
import '../../features/addresses/presentation/pages/addresses_page.dart';
import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/domain/entities/image_ref.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/family/presentation/pages/family_page.dart';
import '../../features/favourites/presentation/pages/favourites_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/location/presentation/pages/location_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/order_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/product/presentation/pages/product_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/shell/presentation/pages/customer_shell.dart';
import '../common/go_router_observer.dart';
import '../di/di_exports.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

const Set<String> guestOnlyRoutes = {
  AppRoutes.welcome,
  AppRoutes.auth,
  AppRoutes.otp,
};

final Set<String> publicRoutes = {...guestOnlyRoutes};

bool isProtectedRoute(String location) =>
    !guestOnlyRoutes.contains(Uri.parse(location).path);

String? redirectForGuest({
  required String location,
  required SessionNotifier session,
}) {
  if (!session.isResolved || session.isAuthenticated) return null;
  if (!isProtectedRoute(location)) return null;
  return AppRoutes.authFor(from: location);
}

String? redirectForLocation({
  required String location,
  required SessionNotifier session,
}) {
  if (!session.isAuthenticated || !session.isLocationResolved) return null;
  if (session.hasLocation) return null;

  final path = Uri.parse(location).path;
  if (path == AppRoutes.location || guestOnlyRoutes.contains(path)) return null;
  return AppRoutes.locationFor(from: location);
}

String? redirectForMember({
  required String location,
  required SessionNotifier session,
}) {
  if (!session.isResolved || !session.isAuthenticated) return null;

  final uri = Uri.parse(location);
  if (!guestOnlyRoutes.contains(uri.path)) return null;

  final from = uri.queryParameters[AppRoutes.fromQuery];
  final safe = from != null &&
      from.startsWith('/') &&
      !guestOnlyRoutes.contains(Uri.parse(from).path);
  return safe ? from : AppRoutes.home;
}

String? _guard(BuildContext context, GoRouterState state) {
  final session = sl<SessionNotifier>();
  final location = state.uri.toString();
  return redirectForGuest(location: location, session: session) ??
      redirectForMember(location: location, session: session) ??
      redirectForLocation(location: location, session: session);
}

String _id(GoRouterState state) => state.pathParameters['id'] ?? '';

List<RouteBase> _details({bool checkout = false}) => [
      if (checkout)
        GoRoute(
          path: AppRoutes.checkoutSegment,
          builder: (context, state) => const CheckoutPage(),
        ),
      GoRoute(
        path: '${AppRoutes.productSegment}/:id',
        builder: (context, state) => ProductPage(productId: _id(state)),
      ),
      GoRoute(
        path: '${AppRoutes.familySegment}/:id',
        builder: (context, state) => FamilyPage(familyId: _id(state)),
      ),
      GoRoute(
        path: '${AppRoutes.orderSegment}/:id',
        builder: (context, state) => OrderPage(
          orderId: _id(state),
          productPhotos: switch (state.extra) {
            final Map<String, ImageRef> photos => photos,
            _ => const {},
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.notificationsSegment,
        builder: (context, state) => const NotificationsPage(),
      ),
    ];

GoRoute _addressForm(String path) => GoRoute(
      path: path,
      builder: (context, state) => AddressFormPage(
        initial: state.extra is Address ? state.extra! as Address : null,
      ),
    );

List<RouteBase> _account() => [
      GoRoute(
        path: AppRoutes.orderSegment,
        builder: (context, state) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.favouritesSegment,
        builder: (context, state) => const FavouritesPage(),
      ),
      GoRoute(
        path: AppRoutes.addressesSegment,
        builder: (context, state) => const AddressesPage(),
        routes: [_addressForm(AppRoutes.newSegment)],
      ),
    ];

StatefulShellBranch _branch(
  String path,
  Widget Function(GoRouterState state) page, {
  bool checkout = false,
  List<RouteBase> extra = const [],
}) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => page(state),
          routes: [..._details(checkout: checkout), ...extra],
        ),
      ],
    );

bool _isProductLocation(Uri uri) =>
    uri.pathSegments.contains(AppRoutes.productSegment);

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.welcome,
  debugLogDiagnostics: true,
  observers: [CustomNavigatorObserver(navigatorName: 'root')],
  refreshListenable: sl<SessionNotifier>(),
  redirect: _guard,
  routes: [
    GoRoute(
      path: AppRoutes.welcome,
      builder: (context, state) => const WelcomePage(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      builder: (context, state) => AuthPage(
        initialMode:
            state.uri.queryParameters[AppRoutes.tabQuery] == AppRoutes.signupTab
                ? AuthMode.signup
                : AuthMode.login,
        from: state.uri.queryParameters[AppRoutes.fromQuery],
      ),
    ),
    GoRoute(
      path: AppRoutes.location,
      builder: (context, state) => LocationPage(
        from: state.uri.queryParameters[AppRoutes.fromQuery],
      ),
    ),
    GoRoute(
      path: AppRoutes.otp,
      redirect: (context, state) =>
          state.extra is OtpChallenge ? null : AppRoutes.auth,
      builder: (context, state) =>
          OtpPage(challenge: state.extra! as OtpChallenge),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => CustomerShell(
        navigationShell: navigationShell,
        showNav: !_isProductLocation(state.uri),
      ),
      branches: [
        _branch(AppRoutes.home, (state) => const HomePage()),
        _branch(AppRoutes.explore, (state) => const ExplorePage()),
        _branch(
          AppRoutes.search,
          (state) => SearchPage(
            key: ValueKey(state.uri.query),
            initialQuery: state.uri.queryParameters[AppRoutes.searchQuery],
            initialCategoryId:
                state.uri.queryParameters[AppRoutes.categoryQuery],
          ),
        ),
        _branch(
          AppRoutes.cart,
          (state) => const CartPage(),
          checkout: true,
          extra: [
            _addressForm('${AppRoutes.addressesSegment}/${AppRoutes.newSegment}'),
          ],
        ),
        _branch(
          AppRoutes.profile,
          (state) => const ProfilePage(),
          extra: _account(),
        ),
      ],
    ),
  ],
);
