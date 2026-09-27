import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      log('🟢 Bloc/Cubit Created: ${bloc.runtimeType}');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      log('📥 Event Added: ${event.runtimeType} in ${bloc.runtimeType}');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      log('🔄 State Changed: ${bloc.runtimeType}, '
          'from ${change.currentState} to ${change.nextState}');
    }
  }

  @override
  void onTransition(Bloc bloc, Transition transition) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      log('🔀 Transition: ${bloc.runtimeType}, '
          'from ${transition.currentState} to ${transition.nextState} '
          'with event ${transition.event}');
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    log('❌ Error in ${bloc.runtimeType}: $error',
        error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase bloc) {
    if (kDebugMode) {
      log('🛑 Bloc/Cubit Closed: ${bloc.runtimeType}');
    }
    super.onClose(bloc);
  }
}
