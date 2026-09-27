import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/pill_chip.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/location_setup_cubit.dart';

class LocationPage extends StatelessWidget {
  final String? from;

  const LocationPage({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      key: ValueKey(context.locale.languageCode),
      create: (_) => sl<LocationSetupCubit>()..load(),
      child: _LocationView(from: from),
    );
  }
}

class _LocationView extends StatelessWidget {
  final String? from;

  const _LocationView({this.from});

  void _onState(BuildContext context, LocationSetupState state) {
    final saved = state.saved;
    if (state.status == LocationSetupStatus.saved && saved != null) {
      context.read<LocationCubit>().adopt(saved);
      final target = from;
      context.go(
        target != null && target.startsWith('/') && target != AppRoutes.location
            ? target
            : AppRoutes.home,
      );
      return;
    }
    final message = state.errorMessage;
    if (message != null && state.countries.isNotEmpty) {
      showAppToast(context, message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_location'.tr(),
            title: 'title_location'.tr(),
            onBack: context.canPop() ? () => context.pop() : null,
          ),
          Expanded(
            child: BlocConsumer<LocationSetupCubit, LocationSetupState>(
              listenWhen: (a, b) =>
                  a.status != b.status || a.errorMessage != b.errorMessage,
              listener: _onState,
              builder: (context, state) => switch (state.status) {
                LocationSetupStatus.loading => const LoadingView(),
                LocationSetupStatus.failed => ErrorView(
                    message: state.errorMessage,
                    onRetry: context.read<LocationSetupCubit>().load,
                  ),
                _ => _buildForm(context, state),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, LocationSetupState state) {
    final p = context.palette;
    final cubit = context.read<LocationSetupCubit>();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 30),
      children: [
        Text(
          'location_intro'.tr(),
          style: AppStrings.w400(12.5, 1.7).c(p.neutral700),
        ),
        const SizedBox(height: 22),
        SectionLabel('location_country'.tr()),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final country in state.countries)
              PillChip(
                label: country.name,
                selected: country == state.country,
                onTap: () => cubit.selectCountry(country),
              ),
          ],
        ),
        if (state.country != null) ...[
          const SizedBox(height: 22),
          SectionLabel('location_governorate'.tr()),
          const SizedBox(height: 10),
          if (state.loadingGovernorates)
            const LoadingView(padding: EdgeInsets.symmetric(vertical: 20))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final governorate in state.governorates)
                  PillChip(
                    label: governorate.name,
                    selected: governorate == state.governorate,
                    onTap: () => cubit.selectGovernorate(governorate),
                  ),
              ],
            ),
        ],
        const SizedBox(height: 28),
        AppButton(
          label: 'location_save'.tr(),
          isLoading: state.status == LocationSetupStatus.saving,
          onPressed: state.canSave ? cubit.save : null,
        ),
      ],
    );
  }
}
