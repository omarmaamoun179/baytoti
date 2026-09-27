import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/phone.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/otp_challenge.dart';
import '../cubit/otp_verify_cubit.dart';
import '../widgets/otp_code_boxes.dart';
import '../widgets/otp_keypad.dart';

class OtpPage extends StatelessWidget {
  final OtpChallenge challenge;

  const OtpPage({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<OtpVerifyCubit>(param1: challenge),
      child: const _OtpView(),
    );
  }
}

class _OtpView extends StatelessWidget {
  const _OtpView();

  void _onState(BuildContext context, OtpVerifyState state) {
    final session = state.session;
    if (state.status == OtpVerifyStatus.verified && session != null) {
      context.read<AuthCubit>().completeSignIn(session.customer);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: MultiBlocListener(
        listeners: [
          BlocListener<OtpVerifyCubit, OtpVerifyState>(
            listenWhen: (a, b) => a.status != b.status,
            listener: _onState,
          ),
          BlocListener<OtpVerifyCubit, OtpVerifyState>(
            listenWhen: (a, b) =>
                b.errorMessage != null && a.errorMessage != b.errorMessage,
            listener: (context, state) =>
                showAppToast(context, state.errorMessage!, isError: true),
          ),
          BlocListener<OtpVerifyCubit, OtpVerifyState>(
            listenWhen: (a, b) => a.resends != b.resends,
            listener: (context, _) => showAppToast(context, 'otp_resent'.tr()),
          ),
        ],
        child: Column(
          children: [
            AppHeader(
              kicker: 'kicker_otp'.tr(),
              title: 'title_otp'.tr(),
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 26, 18, 30),
                child: BlocBuilder<OtpVerifyCubit, OtpVerifyState>(
                  builder: (context, state) => _buildBody(context, state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OtpVerifyState state) {
    final p = context.palette;
    final cubit = context.read<OtpVerifyCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('otp_title'.tr(), style: AppStrings.w800(24, 1.2).c(p.text)),
        const SizedBox(height: 8),
        Text(
          'otp_sent_to'.tr(
            args: ['\u2066${displayPhone(state.challenge.phone)}\u2069'],
          ),
          style: AppStrings.w400(12.5, 1.7).c(p.neutral700),
        ),
        if (state.challenge.demoCode case final code?) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: p.amberTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'otp_demo_code'.tr(args: ['\u2066$code\u2069']),
              style: AppStrings.w600(12, 1.5).c(p.amberInk),
            ),
          ),
        ],
        const SizedBox(height: 20),
        SectionLabel('otp_code'.tr()),
        const SizedBox(height: 9),
        OtpCodeBoxes(
          code: state.code,
          digits: state.challenge.digits,
          rejections: state.rejections,
        ),
        const SizedBox(height: 20),
        OtpKeypad(onDigit: cubit.addDigit, onBackspace: cubit.removeDigit),
        const SizedBox(height: 20),
        AppButton(
          label: 'otp_verify'.tr(),
          isLoading: state.isVerifying,
          onPressed: state.isComplete ? cubit.verify : null,
        ),
        const SizedBox(height: 20),
        _buildResend(context, state),
      ],
    );
  }

  Widget _buildResend(BuildContext context, OtpVerifyState state) {
    final p = context.palette;
    final muted = AppStrings.w400(11.5, 1).c(p.neutral600);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('otp_no_code'.tr(), style: muted),
        const SizedBox(width: 6),
        if (state.canResend)
          AppTextButton(
            label: 'otp_resend'.tr(),
            onPressed: context.read<OtpVerifyCubit>().resend,
          )
        else
          Text(
            'otp_resend_in'.tr(args: ['${state.resendIn}']),
            style: AppStrings.w800(11.5, 1).c(p.neutral500),
          ),
      ],
    );
  }
}
