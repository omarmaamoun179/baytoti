part of 'di_exports.dart';

Future<void> initDependencies() async {
  await _registerAppInfo();
  await _registerStorage();
  _registerNetwork();
  _registerAppCubits();
  _registerCatalogFeature();
  _registerAuthFeature();
  _registerLocationFeature();
  _registerAddressesFeature();
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

void _registerCatalogFeature() {
  sl.registerLazySingleton<FavouritesDataSource>(
    () => FavouritesRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<FavouritesRepository>(
    () => FavouritesRepositoryImpl(sl<FavouritesDataSource>()),
  );
  sl.registerLazySingleton(
    () => SetFavouriteUseCase(sl<FavouritesRepository>()),
  );
  sl.registerLazySingleton(
    () => GetFavouritesUseCase(sl<FavouritesRepository>()),
  );
  sl.registerFactory(() => FavouritesCubit(sl(), sl()));
}

void _registerAuthFeature() {
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthRemoteDataSource(sl<NetworkService>()),
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

void _registerLocationFeature() {
  sl.registerLazySingleton<LocationDataSource>(
    () => LocationRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<LocationLocalDataSource>(
    () => LocationLocalDataSourceImpl(sl<CacheService>()),
  );
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      sl<LocationDataSource>(),
      sl<LocationLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => GetCountriesUseCase(sl<LocationRepository>()));
  sl.registerLazySingleton(
    () => GetGovernoratesUseCase(sl<LocationRepository>()),
  );
  sl.registerLazySingleton(
    () => GetLocationContextUseCase(sl<LocationRepository>()),
  );
  sl.registerLazySingleton(
    () => GetCachedLocationUseCase(sl<LocationRepository>()),
  );
  sl.registerLazySingleton(
    () => SetManualLocationUseCase(sl<LocationRepository>()),
  );
  sl.registerLazySingleton(() => ForgetLocationUseCase(sl<LocationRepository>()));

  sl.registerLazySingleton<LocationCubit>(
    () => LocationCubit(sl(), sl(), sl<SessionNotifier>()),
  );
  sl.registerFactory(() => LocationSetupCubit(sl(), sl(), sl()));
}

void _registerAddressesFeature() {
  sl.registerLazySingleton<AddressesDataSource>(
    () => AddressesRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<AddressesRepository>(
    () => AddressesRepositoryImpl(sl<AddressesDataSource>()),
  );

  sl.registerLazySingleton(() => GetAddressesUseCase(sl<AddressesRepository>()));
  sl.registerLazySingleton(
    () => CreateAddressUseCase(sl<AddressesRepository>()),
  );
  sl.registerLazySingleton(
    () => UpdateAddressUseCase(sl<AddressesRepository>()),
  );
  sl.registerLazySingleton(
    () => DeleteAddressUseCase(sl<AddressesRepository>()),
  );
  sl.registerLazySingleton(
    () => SetDefaultAddressUseCase(sl<AddressesRepository>()),
  );

  sl.registerFactory(() => AddressesCubit(sl(), sl(), sl()));
  sl.registerFactory(() => AddressFormCubit(sl(), sl()));
}

void _registerCartFeature() {
  sl.registerLazySingleton<CartDataSource>(
    () => CartRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(sl<CartDataSource>()),
  );

  sl.registerLazySingleton(() => GetCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => AddToCartUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl<CartRepository>()));
  sl.registerLazySingleton(() => RemoveCartItemUseCase(sl<CartRepository>()));

  sl.registerLazySingleton<CartCubit>(
    () => CartCubit(sl(), sl(), sl(), sl(), sl<SessionNotifier>()),
  );
}

void _registerHomeFeature() {
  sl.registerLazySingleton<HomeDataSource>(
    () => HomeRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(sl<HomeDataSource>()),
  );
  sl.registerLazySingleton(() => GetHomeUseCase(sl<HomeRepository>()));
  sl.registerFactory(() => HomeCubit(sl()));
}

void _registerNotificationsFeature() {
  sl.registerLazySingleton<NotificationsDataSource>(
    () => NotificationsRemoteDataSource(sl<NetworkService>()),
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
    () => ProfileRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl<ProfileDataSource>()),
  );

  sl.registerLazySingleton(() => GetProfileUseCase(sl<ProfileRepository>()));

  sl.registerFactory(() => ProfileCubit(sl()));
}

void _registerExploreFeature() {
  sl.registerLazySingleton<ExploreDataSource>(
    () => ExploreRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ExploreRepository>(
    () => ExploreRepositoryImpl(sl<ExploreDataSource>()),
  );

  sl.registerLazySingleton(() => GetExploreUseCase(sl<ExploreRepository>()));

  sl.registerFactory(() => ExploreCubit(sl<GetExploreUseCase>()));
}

void _registerSearchFeature() {
  sl.registerLazySingleton<SearchDataSource>(
    () => SearchRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(sl<SearchDataSource>()),
  );

  sl.registerLazySingleton(
    () => SearchProductsUseCase(sl<SearchRepository>()),
  );
  sl.registerLazySingleton(
    () => GetSearchCategoriesUseCase(sl<SearchRepository>()),
  );

  sl.registerFactory(
    () => SearchCubit(
      sl<SearchProductsUseCase>(),
      sl<GetSearchCategoriesUseCase>(),
      sl<SetFavouriteUseCase>(),
    ),
  );
}

void _registerFamilyFeature() {
  sl.registerLazySingleton<FamilyDataSource>(
    () => FamilyRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<FamilyRepository>(
    () => FamilyRepositoryImpl(sl<FamilyDataSource>()),
  );

  sl.registerLazySingleton(() => GetFamilyUseCase(sl<FamilyRepository>()));
  sl.registerLazySingleton(
    () => GetFamilyProductsUseCase(sl<FamilyRepository>()),
  );

  sl.registerFactory(
    () => FamilyCubit(sl<GetFamilyUseCase>(), sl<GetFamilyProductsUseCase>()),
  );
}

void _registerProductFeature() {
  sl.registerLazySingleton<ProductDataSource>(
    () => ProductRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(
      sl<ProductDataSource>(),
      sl<FavouritesDataSource>(),
    ),
  );

  sl.registerLazySingleton(() => GetProductUseCase(sl<ProductRepository>()));
  sl.registerLazySingleton(
    () => GetProductReviewsUseCase(sl<ProductRepository>()),
  );

  sl.registerFactory(
    () => ProductCubit(
      sl<GetProductUseCase>(),
      sl<GetProductReviewsUseCase>(),
      sl<SetFavouriteUseCase>(),
    ),
  );
}

void _registerCheckoutFeature() {
  sl.registerLazySingleton<CheckoutDataSource>(
    () => CheckoutRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<CheckoutRepository>(
    () => CheckoutRepositoryImpl(sl<CheckoutDataSource>()),
  );

  sl.registerLazySingleton(
    () => GetCheckoutAddressesUseCase(sl<CheckoutRepository>()),
  );
  sl.registerLazySingleton(() => PlaceOrderUseCase(sl<CheckoutRepository>()));

  sl.registerFactory(() => CheckoutCubit(sl(), sl()));
}

void _registerOrdersFeature() {
  sl.registerLazySingleton<OrdersDataSource>(
    () => OrdersRemoteDataSource(sl<NetworkService>()),
  );
  sl.registerLazySingleton<OrdersRepository>(
    () => OrdersRepositoryImpl(sl<OrdersDataSource>()),
  );

  sl.registerLazySingleton(() => GetOrdersUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => GetOrderUseCase(sl<OrdersRepository>()));
  sl.registerLazySingleton(() => CancelOrderUseCase(sl<OrdersRepository>()));

  sl.registerFactory(() => OrderCubit(sl(), sl(), sl()));
  sl.registerFactory(() => OrdersCubit(sl()));
}

Future<void> resetDependencies() => sl.reset();
