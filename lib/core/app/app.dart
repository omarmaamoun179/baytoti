import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/di_exports.dart';
import '../routing/app_router.dart';
import '../theme/app_theme.dart';
import '../utils/app_lifecycle_manager.dart';
import '../utils/money.dart';
import '../utils/screen_util_scope.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NetworkCubit>.value(value: sl<NetworkCubit>()),
        BlocProvider<AuthCubit>.value(value: sl<AuthCubit>()),
        BlocProvider<CartCubit>.value(value: sl<CartCubit>()),
        BlocProvider<LocationCubit>.value(value: sl<LocationCubit>()),
      ],
      child: ScreenUtilScope(
        child: Builder(
          builder: (context) {
            Money.languageCode = context.locale.languageCode;
            return AppLifecycleManager(
              child: MaterialApp.router(
                onGenerateTitle: (context) => 'app_name'.tr(),
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                routerConfig: appRouter,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                locale: context.locale,
                builder: (context, child) =>
                    AnnotatedRegion<SystemUiOverlayStyle>(
                  value: AppTheme.overlayStyle,
                  child: DevicePreview.appBuilder(context, child),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
