import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'routes.dart';

extension AppNavigation on BuildContext {
  String get currentTab {
    final segments = GoRouterState.of(this).uri.pathSegments;
    final root = segments.isEmpty ? '' : '/${segments.first}';
    return AppRoutes.tabs.contains(root) ? root : AppRoutes.home;
  }

  String get currentLocation => GoRouterState.of(this).uri.toString();

  Future<T?> pushInTab<T>(String segment, [String? id]) =>
      push<T>('$currentTab/$segment${id == null ? '' : '/$id'}');

  Future<void> openProduct(String slug) =>
      pushInTab(AppRoutes.productSegment, slug);

  Future<void> openFamily(String slug) =>
      pushInTab(AppRoutes.familySegment, slug);

  Future<void> openOrder(String orderId) =>
      pushInTab(AppRoutes.orderSegment, orderId);

  Future<void> openNotifications() =>
      pushInTab(AppRoutes.notificationsSegment);

  void openAuth({bool signup = false}) =>
      push(AppRoutes.authFor(from: currentLocation, signup: signup));
}
