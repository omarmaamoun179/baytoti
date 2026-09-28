import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/routing/routes.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/shell/presentation/pages/customer_shell.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_network.dart';

StatefulShellBranch _branch(String path) => StatefulShellBranch(
      routes: [
        GoRoute(
          path: path,
          builder: (_, _) => Text('root $path'),
          routes: [
            GoRoute(
              path: 'inner',
              builder: (_, _) => Text('inner $path'),
            ),
          ],
        ),
      ],
    );

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  late GoRouter router;

  Future<void> pumpShell(WidgetTester tester, String initialLocation) async {
    final cart = CartRepositoryImpl(CartRemoteDataSource(FakeNetwork()));
    final cartCubit = CartCubit(
      GetCartUseCase(cart),
      AddToCartUseCase(cart),
      UpdateCartItemUseCase(cart),
      RemoveCartItemUseCase(cart),
      SessionNotifier(),
    );
    addTearDown(cartCubit.close);

    router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) =>
              CustomerShell(navigationShell: navigationShell),
          branches: [for (final tab in AppRoutes.tabs) _branch(tab)],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(EasyLocalization(
        supportedLocales: const [Locale('ar'), Locale('en')],
        path: 'assets/translations',
        startLocale: const Locale('en'),
        fallbackLocale: const Locale('en'),
        saveLocale: false,
        child: Builder(
          builder: (context) => BlocProvider<CartCubit>.value(
            value: cartCubit,
            child: ScreenUtilScope(
              child: Builder(
                builder: (_) => MaterialApp.router(
                  theme: AppTheme.light,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  routerConfig: router,
                ),
              ),
            ),
          ),
        ),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a tab opened from another tab shows its root, not its inner page',
      (tester) async {
    await pumpShell(tester, '/profile/inner');
    expect(find.text('inner /profile'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('root /home'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('root /profile'), findsOneWidget);
    expect(find.text('inner /profile'), findsNothing);
  });

  testWidgets('the current tab goes back to its root', (tester) async {
    await pumpShell(tester, '/explore/inner');
    expect(find.text('inner /explore'), findsOneWidget);

    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();

    expect(find.text('root /explore'), findsOneWidget);
    expect(router.state.uri.path, AppRoutes.explore);
  });
}
