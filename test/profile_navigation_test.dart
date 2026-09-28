import 'package:baytoti/core/app/session_notifier.dart';
import 'package:baytoti/core/domain/failure.dart';
import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/token_store.dart';
import 'package:baytoti/core/routing/routes.dart';
import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/auth/data/datasources/auth_data_source.dart';
import 'package:baytoti/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:baytoti/features/auth/data/models/auth_models.dart';
import 'package:baytoti/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:baytoti/features/auth/domain/usecases/auth_usecases.dart';
import 'package:baytoti/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:baytoti/features/cart/data/datasources/cart_data_source.dart';
import 'package:baytoti/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:baytoti/features/cart/domain/usecases/cart_usecases.dart';
import 'package:baytoti/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:baytoti/features/profile/data/datasources/profile_data_source.dart';
import 'package:baytoti/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:baytoti/features/profile/domain/usecases/profile_usecases.dart';
import 'package:baytoti/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:baytoti/features/profile/presentation/pages/profile_page.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_network.dart';

class _NoSession implements AuthLocalDataSource {
  @override
  Future<Either<Failure, Unit>> saveSession(
    TokenPair tokens,
    CustomerModel customer,
  ) async =>
      const Right(unit);

  @override
  Future<Either<Failure, CustomerModel?>> readSession() async =>
      const Right(null);

  @override
  Future<Either<Failure, Unit>> clearSession() async => const Right(unit);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('every profile row opens its own screen under the profile tab',
      (tester) async {
    final network = FakeNetwork()
      ..replySample('GET', ApiEndPoint.me, 'profile/me.cloak_shape.json');
    GetIt.instance.registerFactory(
      () => ProfileCubit(GetProfileUseCase(
        ProfileRepositoryImpl(ProfileRemoteDataSource(network)),
      )),
    );

    final session = SessionNotifier();
    final auth = AuthRepositoryImpl(AuthRemoteDataSource(network), _NoSession());
    final authCubit = AuthCubit(
      RestoreSessionUseCase(auth),
      SignOutUseCase(auth),
      ClearSessionUseCase(auth),
      session,
    );
    final cart = CartRepositoryImpl(CartRemoteDataSource(network));
    final cartCubit = CartCubit(
      GetCartUseCase(cart),
      AddToCartUseCase(cart),
      UpdateCartItemUseCase(cart),
      RemoveCartItemUseCase(cart),
      session,
    );
    addTearDown(authCubit.close);
    addTearDown(cartCubit.close);

    final router = GoRouter(
      initialLocation: AppRoutes.profile,
      routes: [
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const ProfilePage(),
          routes: [
            for (final segment in [
              AppRoutes.orderSegment,
              AppRoutes.favouritesSegment,
              AppRoutes.addressesSegment,
              AppRoutes.notificationsSegment,
            ])
              GoRoute(
                path: segment,
                builder: (_, state) => Text('at ${state.uri.path}'),
              ),
          ],
        ),
        GoRoute(
          path: AppRoutes.location,
          builder: (_, state) => Text(
            'at ${state.uri.path} from '
            '${state.uri.queryParameters[AppRoutes.fromQuery]}',
          ),
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
          builder: (context) => MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: authCubit),
              BlocProvider<CartCubit>.value(value: cartCubit),
            ],
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

    expect(find.text('Support'), findsNothing);

    for (final (label, path) in [
      ('My orders', '/profile/orders'),
      ('Favourites', '/profile/favourites'),
      ('Addresses', '/profile/addresses'),
      ('Delivery area', '/location from /profile'),
      ('Notifications', '/profile/notifications'),
    ]) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(find.text('at $path'), findsOneWidget, reason: label);

      router.pop();
      await tester.pumpAndSettle();
    }
  });
}
