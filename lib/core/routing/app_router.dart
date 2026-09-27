import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/entities/otp_challenge.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/pages/otp_page.dart';
import '../../features/auth/presentation/pages/welcome_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/family/presentation/pages/family_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/order_page.dart';
import '../../features/product/presentation/pages/product_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/shell/presentation/pages/customer_shell.dart';
import '../common/go_router_observer.dart';
import '../di/di_exports.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

const Set<String> protectedTabs = {AppRoutes.cart, AppRoutes.profile};

const Set<String> protectedSegments = {
  AppRoutes.orderSegment,
  AppRoutes.checkoutSegment,
  AppRoutes.notificationsSegment,
};

const Set<String> guestOnlyRoutes = {
  AppRoutes.welcome,
  AppRoutes.auth,
  AppRoutes.otp,
};

final Set<String> publicRoutes = {
  ...guestOnlyRoutes,
  for (final tab in [AppRoutes.home, AppRoutes.explore, AppRoutes.search]) ...[
    tab,
    '$tab/${AppRoutes.productSegment}/:id',
    '$tab/${AppRoutes.familySegment}/:id',
  ],
};

bool isProtectedRoute(String location) {
  final uri = Uri.parse(location);
  final path = uri.path;

  if (protectedTabs.any((tab) => path == tab || path.startsWith('$tab/'))) {
    return true;
  }
  return uri.pathSegments.any(protectedSegments.contains);
}

String? redirectForGuest({
  required String location,
  required SessionNotifier session,
}) {
  if (!session.isResolved || session.isAuthenticated) return null;
  if (!isProtectedRoute(location)) return null;
  return AppRoutes.authFor(from: location);
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
      redirectForMember(location: location, session: session);
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
        builder: (context, state) => OrderPage(orderId: _id(state)),
      ),
      GoRoute(
        path: AppRoutes.notificationsSegment,
        builder: (context, state) => const NotificationsPage(),
      ),
    ];

StatefulShellBranch _branch(
  String path,
  Widget Function(GoRouterState state) page, {
  bool checkout = false,
}) =>
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (context, state) => page(state),
          routes: _details(checkout: checkout),
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
        _branch(AppRoutes.cart, (state) => const CartPage(), checkout: true),
        _branch(AppRoutes.profile, (state) => const ProfilePage()),
      ],
    ),
  ],
);
