part of 'di_exports.dart';

const bool useMockData = bool.fromEnvironment(
  'USE_MOCK_DATA',
  defaultValue: true,
);

Future<void> initDependencies() async {
  await _registerAppInfo();
  await _registerStorage();
  _registerNetwork();
  _registerAppCubits();
  _registerFixtures();
  _registerCatalogFeature();
  _registerAuthFeature();
  _registerCartFeature();
  _registerHomeFeature();
  _registerNotificationsFeature();
  _registerProfileFeature();
  _registerExploreFeature();
  _registerSearchFeature();
  _registerFamilyFeature();
  _registerProductFeature();
  _registerCheckoutFeature();
  _registerOrdersFeature();
}

Future<void> _registerAppInfo() async {
  final appInfoService = AppInfoServiceImpl();
  sl.registerSingleton<AppInfoServiceImpl>(appInfoService);
  sl.registerSingleton<AppInfo>(await appInfoService.init());
  sl.registerSingleton<LauncherService>(LauncherServiceImpl());
}

Future<void> _registerStorage() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());

  sl.registerSingleton<SecureStorageService>(
    SecureStorageServiceImpl(
      sl<FlutterSecureStorage>(),
      sl<SharedPreferences>(),
    ),
  );
  sl.registerSingleton<SharedPrefService>(
    SharedPrefServiceImpl(sl<SharedPreferences>()),
  );

  await sl<SecureStorageService>().clearOnReinstall();

  sl.registerSingleton<CacheService>(
    CacheServiceImpl(sl<SharedPrefService>(), sl<SecureStorageService>()),
  );
  sl.registerSingleton<TokenStore>(
    SecureTokenStore(sl<SecureStorageService>()),
  );
}

void _registerNetwork() {
  sl.registerSingleton<InternetConnection>(InternetConnection());
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl<InternetConnection>()));
  sl.registerSingleton<NetworkCubit>(NetworkCubit(sl<NetworkInfo>()));

  sl.registerSingleton<NetworkServiceUtil>(
    NetworkServiceUtilImpl(sl<CacheService>(), sl<TokenStore>(), sl<AppInfo>()),
  );
  sl.registerSingleton<NetworkService>(
    NetworkServiceImpl(
      sl<NetworkServiceUtil>(),
      onSessionExpired: () => sl<AuthCubit>().sessionExpired(),
    ),
  );
}

void _registerAppCubits() {
  sl.registerSingleton<SessionNotifier>(SessionNotifier());
}

void _registerFixtures() {
  sl.registerLazySingleton<FixtureBackend>(FixtureBackend.new);
  sl.registerSingleton<ContentLanguage>(
    () async => await sl<NetworkServiceUtil>().getLanguageCode() ?? 'ar',
  );
}

void _registerCatalogFeature() {
  sl.registerLazySingleton<FavouritesDataSource>(
    () => useMockData
        ? FavouritesMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : FavouritesRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<FavouritesRepository>(
    () => FavouritesRepositoryImpl(sl<FavouritesDataSource>()),
  );
  sl.registerLazySingleton(
    () => SetFavouriteUseCase(sl<FavouritesRepository>()),
  );
}

void _registerAuthFeature() {
  sl.registerLazySingleton<AuthDataSource>(
    () => useMockData
        ? AuthMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : AuthRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl<TokenStore>(), sl<CacheService>()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl<AuthDataSource>(), sl<AuthLocalDataSource>()),
  );

  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LoginUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RequestOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ResendOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RestoreSessionUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => SignOutUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => ClearSessionUseCase(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthCubit>(
    () => AuthCubit(sl(), sl(), sl(), sl<SessionNotifier>()),
  );
  sl.registerFactoryParam<OtpRequestCubit, AuthMode, void>(
    (mode, _) => OtpRequestCubit(sl(), sl(), sl(), mode: mode),
  );
  sl.registerFactoryParam<OtpVerifyCubit, OtpChallenge, void>(
    (challenge, _) => OtpVerifyCubit(sl(), sl(), challenge),
  );
}

void _registerCartFeature() {
  sl.registerLazySingleton<CartDataSource>(
    () => useMockData
        ? CartMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : CartRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(sl<CartDataSource>()),
  );

  sl.registerLazySingleton(() => GetCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => RemoveCartItemUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => ApplyCouponUseCase(sl<CartRepository>()));

  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(sl(), sl(), sl(), sl(), sl(), sl<SessionNotifier>()),
  );
}

void _registerHomeFeature() {
  sl.registerLazySingleton<HomeDataSource>(
    () => useMockData
        ? HomeMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : HomeRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeDataSource>()),
  );
  sl.registerLazySingleton(() => GetHomeUseCase(sl<HomeRepository>()));
  sl.registerFactory(() => HomeCubit(sl()));
}

void _registerNotificationsFeature() {
  sl.registerLazySingleton<NotificationsDataSource>(
    () => useMockData
        ? NotificationsMockDataSource(
            sl<FixtureBackend>(),
            sl<ContentLanguage>(),
          )
        : NotificationsRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(sl<NotificationsDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetNotificationsUseCase(sl<NotificationsRepository>()),
  );
  sl.registerLazySingleton(
    () => MarkNotificationsReadUseCase(sl<NotificationsRepository>()),
  );

  sl.registerFactory(() => NotificationsCubit(sl(), sl()));
}

void _registerProfileFeature() {
  sl.registerLazySingleton<ProfileDataSource>(
    () => useMockData
        ? ProfileMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : ProfileRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileDataSource>()),
  );

  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));

  sl.registerFactory(() => ProfileCubit(sl()));
}

void _registerExploreFeature() {
  sl.registerLazySingleton<ExploreDataSource>(
    () => useMockData
        ? ExploreMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : ExploreRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(sl<ExploreDataSource>()),
  );

  sl.registerLazySingleton(() => GetExploreUseCase(sl<ExploreRepository>()));

  sl.registerFactory(() => ExploreCubit(sl<GetExploreUseCase>()));
}

void _registerSearchFeature() {
  sl.registerLazySingleton<SearchDataSource>(
    () => useMockData
        ? SearchMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : SearchRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(sl<SearchDataSource>()),
  );

  sl.registerLazySingleton(
    () => SearchProductsUseCase(sl<SearchRepository>()),
  );

  sl.registerFactory(
    () => SearchCubit(sl<SearchProductsUseCase>(), sl<SetFavouriteUseCase>()),
  );
}

void _registerFamilyFeature() {
  sl.registerLazySingleton<FamilyDataSource>(
    () => useMockData
        ? FamilyMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : FamilyRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(sl<FamilyDataSource>()),
  );

  sl.registerLazySingleton(() => GetFamilyUseCase(sl<FamilyRepository>()));
  sl.registerLazySingleton(
    () => GetFamilyProductsUseCase(sl<FamilyRepository>()),
  );
  sl.registerLazySingleton(() => SetFollowingUseCase(sl<FamilyRepository>()));

  sl.registerFactory(
    () => FamilyCubit(
      sl<GetFamilyUseCase>(),
      sl<GetFamilyProductsUseCase>(),
      sl<SetFollowingUseCase>(),
    ),
  );
}

void _registerProductFeature() {
  sl.registerLazySingleton<ProductDataSource>(
    () => useMockData
        ? ProductMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : ProductRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl<ProductDataSource>()),
  );

  sl.registerLazySingleton(() => GetProductUseCase(sl<ProductRepository>()));

  sl.registerFactory(
    () => ProductCubit(sl<GetProductUseCase>(), sl<SetFavouriteUseCase>()),
  );
}

void _registerCheckoutFeature() {
  sl.registerLazySingleton<CheckoutDataSource>(
    () => useMockData
        ? CheckoutMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : CheckoutRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(sl<CheckoutDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetCheckoutOptionsUseCase(sl<CheckoutRepository>()),
  );
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl<CheckoutRepository>()));

  sl.registerFactory(() => CheckoutCubit(sl(), sl()));
}

void _registerOrdersFeature() {
  sl.registerLazySingleton<OrdersDataSource>(
    () => useMockData
        ? OrdersMockDataSource(sl<FixtureBackend>(), sl<ContentLanguage>())
        : OrdersRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl<OrdersDataSource>()),
  );

  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => GetOrderUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => RateOrderUseCase(sl<OrdersRepository>()));

  sl.registerFactory(() => OrderCubit(sl(), sl(), sl()));
}

Future<void> resetDependencies() => sl.reset();
