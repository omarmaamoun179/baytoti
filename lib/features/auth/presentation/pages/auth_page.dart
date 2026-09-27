import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/otp_challenge.dart';
import '../cubit/otp_request_cubit.dart';
import '../widgets/auth_brand_band.dart';
import '../widgets/auth_form.dart';
import '../widgets/auth_mode_tabs.dart';

class AuthPage extends StatelessWidget {
  final AuthMode initialMode;
  final String? from;

  const AuthPage({super.key, this.initialMode = AuthMode.login, this.from});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OtpRequestCubit>(param1: initialMode),
      child: _AuthView(from: from),
    );
  }
}

class _AuthView extends StatelessWidget {
  final String? from;

  const _AuthView({this.from});

  void _onState(BuildContext context, OtpRequestState state) {
    switch (state.status) {
      case OtpRequestStatus.sent:
        context.read<OtpRequestCubit>().acknowledge();
        context.push(
          Uri(
            path: AppRoutes.otp,
            queryParameters: {AppRoutes.fromQuery: ?from},
          ).toString(),
          extra: state.challenge,
        );
      case OtpRequestStatus.failed:
        final message = [
          ?state.errorMessage,
          ...state.fieldErrors.values,
        ].join('\n');
        showAppToast(
          context,
          message.isEmpty ? 'auth_failed'.tr() : message,
          isError: true,
        );
      case OtpRequestStatus.idle || OtpRequestStatus.submitting:
        break;
    }
  }

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRoutes.home);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: BlocConsumer<OtpRequestCubit, OtpRequestState>(
        listenWhen: (a, b) => a.status != b.status,
        listener: _onState,
        builder: (context, state) => Column(
          children: [
            AppHeader(
              kicker: 'kicker_auth'.tr(),
              title: 'title_auth'.tr(),
              onBack: () => _back(context),
            ),
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthBrandBand(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthModeTabs(
                            mode: state.mode,
                            onChanged: context.read<OtpRequestCubit>().setMode,
                          ),
                          const SizedBox(height: 20),
                          AuthForm(
                            key: ValueKey(state.mode),
                            mode: state.mode,
                            isSubmitting: state.isSubmitting,
                            serverErrors: state.fieldErrors,
                            onInvalid: (message) =>
                                showAppToast(context, message, isError: true),
                            onSubmit: (phone, name) => context
                                .read<OtpRequestCubit>()
                                .submit(phone: phone, fullName: name),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
