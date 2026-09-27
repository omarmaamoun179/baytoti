import 'dart:async';
import 'dart:developer' as developer;

import 'package:device_preview/device_preview.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:requests_inspector/requests_inspector.dart';

import '../common/bloc_observer.dart';
import '../common/localization_service.dart';
import '../di/di_exports.dart';
import '../routing/app_router.dart';
import 'app.dart';

Future<void> bootstrap({Future<void> Function()? onReady}) async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await EasyLocalization.ensureInitialized();

      if (kDebugMode) Bloc.observer = AppBlocObserver();

      await initDependencies();

      await onReady?.call();

      await sl<AuthCubit>().restoreSession();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        developer.log(
          'Flutter error',
          name: 'bootstrap',
          error: details.exception,
          stackTrace: details.stack,
        );
      };

      runApp(
        DevicePreview(
          enabled: false,
          builder: (context) => RequestsInspector(
            enabled: kDebugMode,
            showInspectorOn: ShowInspectorOn.Both,
            navigatorKey: rootNavigatorKey,
            child: LocalizationService.wrap(const App()),
          ),
        ),
      );
    },
    (error, stackTrace) => developer.log(
      'Uncaught zone error',
      name: 'bootstrap',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}
