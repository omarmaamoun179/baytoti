import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/avatar_picker.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../domain/entities/otp_challenge.dart';

class AuthForm extends StatefulWidget {
  static Set<String> fieldsFor(AuthMode mode) => mode == AuthMode.signup
      ? const {'name', 'email', 'phone', 'password', 'password_confirmation'}
      : const {'login', 'phone', 'password'};

  final AuthMode mode;
  final bool isSubmitting;
  final Map<String, String> serverErrors;
  final void Function({
    required String phone,
    required String password,
    String? fullName,
    String? email,
    String? passwordConfirmation,
    String? avatarPath,
  }) onSubmit;
  final ValueChanged<String> onFieldChanged;
  final Future<String?> Function() onPickPhoto;

  const AuthForm({
    super.key,
    required this.mode,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onFieldChanged,
    required this.onPickPhoto,
    this.serverErrors = const {},
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();
  String _e164 = '';
  String? _avatarPath;

  bool get _signup => widget.mode == AuthMode.signup;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await widget.onPickPhoto();
    if (path == null || !mounted) return;
    setState(() => _avatarPath = path);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? true)) return;

    widget.onSubmit(
      phone: _e164,
      password: _password.text,
      fullName: _signup ? _name.text.trim() : null,
      email: _signup ? _email.text.trim() : null,
      passwordConfirmation: _signup ? _passwordConfirmation.text : null,
      avatarPath: _signup ? _avatarPath : null,
    );
  }

  void _passwordChanged() {
    widget.onFieldChanged('password');
    if (_signup) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final errors = widget.serverErrors;
    final phoneError = errors['phone'] ?? errors['login'];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_signup) ...[
            AvatarPicker(
              label: (_avatarPath == null
                      ? 'auth_add_photo'
                      : 'profile_change_photo')
                  .tr(),
              filePath: _avatarPath,
              onPick: widget.isSubmitting ? null : _pickPhoto,
            ),
            const SizedBox(height: 16),
            AppTextFormField(
              label: 'auth_full_name'.tr(),
              controller: _name,
              hint: 'auth_name_hint'.tr(),
              maxLength: RegisterParams.nameMaxLength,
              textInputAction: TextInputAction.next,
              validator: validateName,
              serverError: errors['name'],
              onChanged: (_) => widget.onFieldChanged('name'),
            ),
            const SizedBox(height: 16),
            AppTextFormField(
              label: 'auth_email'.tr(),
              controller: _email,
              hint: 'auth_email_hint'.tr(),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
              serverError: errors['email'],
              onChanged: (_) => widget.onFieldChanged('email'),
            ),
            const SizedBox(height: 16),
          ],
          PhoneTextFormField(
            label: 'auth_phone'.tr(),
            hintText: '5150 2244',
            controller: _phone,
            requiredMessage: 'phone_required'.tr(),
            invalidMessage: 'invalid_phone'.tr(),
            onInputChanged: (number) {
              _e164 = number.phoneNumber ?? '';
              widget.onFieldChanged('phone');
              widget.onFieldChanged('login');
            },
          ),
          if (phoneError != null) FieldErrorText(phoneError),
          const SizedBox(height: 16),
          AppTextFormField(
            label: 'auth_password'.tr(),
            controller: _password,
            hint: 'auth_password_hint'.tr(),
            obscureText: true,
            textInputAction:
                _signup ? TextInputAction.next : TextInputAction.done,
            validator: validatePassword,
            serverError: errors['password'],
            onChanged: (_) => _passwordChanged(),
          ),
          if (_signup) ...[
            const SizedBox(height: 16),
            AppTextFormField(
              label: 'auth_password_confirmation'.tr(),
              controller: _passwordConfirmation,
              hint: 'auth_password_hint'.tr(),
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: (value) =>
                  validatePasswordConfirmation(value, _password.text),
              serverError: errors['password_confirmation'],
              onChanged: (_) => widget.onFieldChanged('password_confirmation'),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: (_signup ? 'auth_cta_signup' : 'auth_cta_login').tr(),
            trailingIcon: AppIcons.forward,
            isLoading: widget.isSubmitting,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          Text(
            'auth_hint'.tr(),
            textAlign: TextAlign.center,
            style: AppStrings.w400(11, 1.6).c(p.neutral600),
          ),
        ],
      ),
    );
  }
}
