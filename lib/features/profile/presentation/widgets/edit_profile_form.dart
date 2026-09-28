import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../auth/domain/entities/customer.dart';
import '../../domain/entities/profile_update.dart';

class EditProfileForm extends StatefulWidget {
  static const Set<String> fields = {'name', 'email', 'avatar'};

  final Customer? initial;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final ValueChanged<String> onFieldChanged;
  final Future<String?> Function() onPickPhoto;
  final ValueChanged<ProfileUpdate> onSubmit;

  const EditProfileForm({
    super.key,
    this.initial,
    required this.isSaving,
    required this.fieldErrors,
    required this.onFieldChanged,
    required this.onPickPhoto,
    required this.onSubmit,
  });

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  String? _avatarPath;
  Map<String, String> _local = const {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initial?.fullName);
    _email = TextEditingController(text: widget.initial?.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  String? _errorFor(String key) => _local[key] ?? widget.fieldErrors[key];

  void _changed(String key) {
    if (_local.containsKey(key)) {
      setState(() => _local = {..._local}..remove(key));
    }
    widget.onFieldChanged(key);
  }

  Future<void> _pickPhoto() async {
    final path = await widget.onPickPhoto();
    if (path == null || !mounted) return;
    setState(() => _avatarPath = path);
    widget.onFieldChanged('avatar');
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final email = _email.text.trim();
    final local = {
      'name': ?validateName(_name.text),
      if (email.isNotEmpty) 'email': ?validateEmail(email),
    };
    setState(() => _local = local);
    if (local.isNotEmpty) return;

    widget.onSubmit(ProfileUpdate(
      name: _name.text.trim(),
      email: email,
      avatarPath: _avatarPath,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AvatarPicker(
            label: 'profile_change_photo'.tr(),
            url: widget.initial?.avatarUrl,
            filePath: _avatarPath,
            error: widget.fieldErrors['avatar'],
            onPick: widget.isSaving ? null : _pickPhoto,
          ),
          const SizedBox(height: 22),
          _field(
            'name',
            _name,
            label: 'auth_full_name'.tr(),
            hint: 'auth_name_hint'.tr(),
            maxLength: ProfileUpdate.nameMaxLength,
            action: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          _field(
            'email',
            _email,
            label: 'auth_email'.tr(),
            hint: 'auth_email_hint'.tr(),
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.done,
          ),
          const SizedBox(height: 26),
          AppButton(
            label: 'profile_save'.tr(),
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _field(
    String key,
    TextEditingController controller, {
    required String label,
    required String hint,
    required TextInputAction action,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    final error = _errorFor(key);

    return LabeledField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: controller,
            hint: hint,
            maxLength: maxLength,
            keyboardType: keyboardType,
            textInputAction: action,
            hasError: error != null,
            onChanged: (_) => _changed(key),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                error,
                style: AppStrings.w400(11, 1.5).c(context.palette.danger),
              ),
            ),
        ],
      ),
    );
  }
}
