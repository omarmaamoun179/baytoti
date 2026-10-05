import 'package:baytoti/core/di/di_exports.dart';
import 'package:baytoti/core/routing/app_router.dart';
import 'package:baytoti/core/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

SessionNotifier _session({required bool authenticated}) {
  final notifier = SessionNotifier();
  authenticated ? notifier.signedIn() : notifier.signedOut();
  return notifier;
}

String? _guest(String location) => redirectForGuest(
      location: location,
      session: _session(authenticated: false),
    );

String? _member(String location) => redirectForMember(
      location: location,
      session: _session(authenticated: true),
    );

List<String> _registeredPaths(List<RouteBase> routes, [String prefix = '']) {
  final paths = <String>[];

  for (final route in routes) {
    switch (route) {
      case GoRoute(:final path, routes: final children):
        final full = path.startsWith('/') ? path : '$prefix/$path';
        paths
          ..add(full)
          ..addAll(_registeredPaths(children, full));
      case StatefulShellRoute(:final branches):
        for (final branch in branches) {
          paths.addAll(_registeredPaths(branch.routes, prefix));
        }
      case ShellRouteBase(routes: final children):
        paths.addAll(_registeredPaths(children, prefix));
      default:
        fail('Unhandled RouteBase subtype: ${route.runtimeType}');
    }
  }
  return paths;
}

String _concrete(String path) => path.replaceAll(':id', 'x1');

void main() {
  late List<String> registered;

  setUpAll(() {
    if (!sl.isRegistered<SessionNotifier>()) {
      sl.registerSingleton<SessionNotifier>(SessionNotifier());
    }
    registered = _registeredPaths(appRouter.configuration.routes);
  });

  tearDownAll(() => sl.reset());

  test('every registered route is either protected or explicitly public', () {
    final unclassified = registered
        .where((path) => !isProtectedRoute(path) && !publicRoutes.contains(path))
        .toList();

    expect(registered, isNotEmpty);
    expect(unclassified, isEmpty);
  });

  test('no public route is also protected', () {
    expect(publicRoutes.where(isProtectedRoute), isEmpty);
  });

  test('no public entry is stale', () {
    expect(publicRoutes.where((p) => !registered.contains(p)), isEmpty);
  });

  test('a guest on a protected route is sent to sign in, and back after', () {
    for (final path in registered.where(isProtectedRoute).map(_concrete)) {
      final redirect = _guest(path);

      expect(redirect, isNotNull, reason: path);
      final uri = Uri.parse(redirect!);
      expect(uri.path, AppRoutes.auth);
      expect(uri.queryParameters[AppRoutes.fromQuery], path);
      expect(_member(path), isNull, reason: path);
    }
  });

  test('public routes let a guest through', () {
    for (final path in publicRoutes.map(_concrete)) {
      expect(_guest(path), isNull, reason: path);
    }
  });

  test('the account screens live under the profile tab', () {
    for (final segment in [
      AppRoutes.editProfileSegment,
      AppRoutes.orderSegment,
      AppRoutes.favouritesSegment,
      AppRoutes.addressesSegment,
      '${AppRoutes.addressesSegment}/${AppRoutes.newSegment}',
    ]) {
      expect(registered, contains('${AppRoutes.profile}/$segment'));
    }
    expect(
      registered,
      contains(
        '${AppRoutes.cart}/${AppRoutes.addressesSegment}/${AppRoutes.newSegment}',
      ),
    );
  });

  test('details nest under every tab they are opened from', () {
    for (final tab in AppRoutes.tabs) {
      expect(registered, contains('$tab/${AppRoutes.productSegment}/:id'));
      expect(registered, contains('$tab/${AppRoutes.familySegment}/:id'));
    }
    expect(
      registered,
      contains('${AppRoutes.cart}/${AppRoutes.checkoutSegment}'),
    );
  });

  group('a signed-in customer', () {
    test('leaves sign-in for where they were going', () {
      expect(_member(AppRoutes.authFor(from: '/cart/checkout')), '/cart/checkout');
      expect(_member('${AppRoutes.otp}?from=%2Fprofile'), '/profile');
    });

    test('never lands back on a guest screen', () {
      expect(_member(AppRoutes.welcome), AppRoutes.home);
      expect(_member(AppRoutes.authFor(from: AppRoutes.otp)), AppRoutes.home);
      expect(_member(AppRoutes.authFor(from: 'https://evil.test')), AppRoutes.home);
    });
  });

  test('an unresolved session never redirects', () {
    final unresolved = SessionNotifier();

    expect(redirectForGuest(location: '/cart', session: unresolved), isNull);
    expect(redirectForMember(location: '/auth', session: unresolved), isNull);
  });

  test('a query string never creates a match', () {
    expect(isProtectedRoute('/welcome?next=/cart/orders/1'), isFalse);
  });

  test('a guest browses home, explore, search, products and stores', () {
    for (final tab in browseTabs) {
      for (final path in [
        tab,
        '$tab/${AppRoutes.productSegment}/x1',
        '$tab/${AppRoutes.familySegment}',
        '$tab/${AppRoutes.familySegment}/x1',
      ]) {
        expect(isProtectedRoute(path), isFalse, reason: path);
        expect(_guest(path), isNull, reason: path);
      }
    }
  });

  test('cart, profile and account screens still need an account', () {
    for (final path in [
      AppRoutes.cart,
      AppRoutes.profile,
      '${AppRoutes.cart}/${AppRoutes.checkoutSegment}',
      '${AppRoutes.cart}/${AppRoutes.productSegment}/x1',
      '${AppRoutes.profile}/${AppRoutes.favouritesSegment}',
      '${AppRoutes.home}/${AppRoutes.orderSegment}/1',
      '${AppRoutes.home}/${AppRoutes.notificationsSegment}',
    ]) {
      expect(isProtectedRoute(path), isTrue, reason: path);
      expect(Uri.parse(_guest(path)!).path, AppRoutes.auth, reason: path);
    }
  });

  group('the browsing location', () {
    SessionNotifier located(bool? hasLocation) {
      final notifier = SessionNotifier()..signedIn();
      if (hasLocation != null) notifier.locationKnown(hasLocation);
      return notifier;
    }

    test('a customer with none is sent to choose one, and back after', () {
      final redirect = redirectForLocation(
        location: '/explore',
        session: located(false),
      );

      final uri = Uri.parse(redirect!);
      expect(uri.path, AppRoutes.location);
      expect(uri.queryParameters[AppRoutes.fromQuery], '/explore');
    });

    test('the location screen itself is never redirected', () {
      expect(
        redirectForLocation(location: AppRoutes.location, session: located(false)),
        isNull,
      );
    });

    test('a customer with a location, or one not yet known, browses on', () {
      expect(redirectForLocation(location: '/home', session: located(true)), isNull);
      expect(redirectForLocation(location: '/home', session: located(null)), isNull);
    });

    test('signing out forgets whether a location was set', () {
      final notifier = located(true)..signedOut();

      expect(notifier.isLocationResolved, isFalse);
      expect(
        redirectForLocation(location: '/home', session: notifier),
        isNull,
      );
    });
  });
}
