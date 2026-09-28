import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/di_exports.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/photo_picker.dart';
import '../../../../core/widgets/app_header.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/edit_profile_cubit.dart';
import '../widgets/edit_profile_form.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<EditProfileCubit>(),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView();

  void _onSaveEnded(BuildContext context, EditProfileState state) {
    final saved = state.saved;
    if (state.isSaved && saved != null) {
      context.read<AuthCubit>().updateCustomer(saved);
      showAppToast(context, 'profile_saved'.tr());
      context.pop();
      return;
    }
    final message = _unshownError(state);
    if (message != null) showAppToast(context, message, isError: true);
  }

  String? _unshownError(EditProfileState state) {
    if (state.fieldErrors.isEmpty) {
      return state.errorMessage ?? 'profile_update_failed'.tr();
    }
    final unshown = [
      for (final entry in state.fieldErrors.entries)
        if (!EditProfileForm.fields.contains(entry.key)) entry.value,
    ];
    return unshown.isEmpty ? null : unshown.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final customer = context.read<AuthCubit>().state.customer;

    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppHeader(
            kicker: 'kicker_profile'.tr(),
            title: 'title_profile_edit'.tr(),
            onBack: () => context.pop(),
          ),
          Expanded(
            child: BlocConsumer<EditProfileCubit, EditProfileState>(
              listenWhen: (previous, current) =>
                  previous.isSaving && !current.isSaving,
              listener: _onSaveEnded,
              builder: (context, state) {
                final cubit = context.read<EditProfileCubit>();
                return EditProfileForm(
                  initial: customer,
                  isSaving: state.isSaving || state.isSaved,
                  fieldErrors: state.fieldErrors,
                  onFieldChanged: cubit.clearFieldError,
                  onPickPhoto: () => pickGalleryPhoto(context),
                  onSubmit: cubit.save,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
