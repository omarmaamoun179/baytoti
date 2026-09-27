import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../domain/entities/address.dart';
import '../cubit/address_form_cubit.dart';
import '../widgets/address_form.dart';

class AddressFormPage extends StatelessWidget {
  final Address? initial;

  const AddressFormPage({super.key, this.initial});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressFormCubit>(),
      child: _AddressFormView(initial: initial),
    );
  }
}

class _AddressFormView extends StatelessWidget {
  final Address? initial;

  const _AddressFormView({this.initial});

  void _onSaveEnded(BuildContext context, AddressFormState state) {
    if (state.isSaved) {
      showAppToast(context, 'address_saved'.tr());
      context.pop(true);
      return;
    }
    final message = _unshownError(state);
    if (message != null) showAppToast(context, message, isError: true);
  }

  String? _unshownError(AddressFormState state) {
    if (state.fieldErrors.isEmpty) {
      return state.errorMessage ?? 'addresses_failed'.tr();
    }
    final unshown = [
      for (final entry in state.fieldErrors.entries)
        if (!AddressForm.fields.contains(entry.key)) entry.value,
    ];
    return unshown.isEmpty ? null : unshown.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final initial = this.initial;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_addresses'.tr(),
            title: initial == null
                ? 'title_address_new'.tr()
                : 'title_address_edit'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<AddressFormCubit, AddressFormState>(
              listenWhen: (previous, current) =>
                  previous.isSaving && !current.isSaving,
              listener: _onSaveEnded,
              builder: (context, state) {
                final cubit = context.read<AddressFormCubit>();
                return AddressForm(
                  initial: initial,
                  isSaving: state.isSaving || state.isSaved,
                  fieldErrors: state.fieldErrors,
                  onFieldChanged: cubit.clearFieldError,
                  onSubmit: (params) => cubit.save(params, id: initial?.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
