import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import '../../../../core/utils/phone.dart';
import '../../../../core/utils/validators/validator_messages.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_icon.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../domain/entities/otp_challenge.dart';
import 'terms_checkbox.dart';

class AuthForm extends StatefulWidget {
  final AuthMode mode;
  final bool isSubmitting;
  final Map<String, String> serverErrors;
  final void Function(String phone, String? fullName) onSubmit;
  final ValueChanged<String> onInvalid;

  const AuthForm({
    super.key,
    required this.mode,
    required this.isSubmitting,
    required this.onSubmit,
    required this.onInvalid,
    this.serverErrors = const {},
  });

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _terms = false;
  Set<String> _invalid = const {};

  bool get _signup => widget.mode == AuthMode.signup;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final phoneValid = _formKey.currentState?.validate() ?? true;
    final problems = <String, String>{
      if (_signup) 'name': ?validateName(_name.text),
      if (_signup && !_terms) 'terms': 'auth_terms_required'.tr(),
    };

    setState(() => _invalid = problems.keys.toSet());
    if (problems.isNotEmpty || !phoneValid) {
      if (problems.isNotEmpty) widget.onInvalid(problems.values.join('\n'));
      return;
    }

    widget.onSubmit(toE164(_phone.text), _signup ? _name.text.trim() : null);
  }

  bool _hasError(String field, String serverKey) =>
      _invalid.contains(field) || widget.serverErrors.containsKey(serverKey);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_signup) ...[
            LabeledField(
              label: 'auth_full_name'.tr(),
              child: AppTextField(
                controller: _name,
                hint: 'auth_name_hint'.tr(),
                maxLength: 100,
                textInputAction: TextInputAction.next,
                hasError: _hasError('name', 'full_name'),
              ),
            ),
            const SizedBox(height: 16),
          ],
          PhoneTextFormField(
            label: 'auth_phone'.tr(),
            hintText: '5150 2244',
            controller: _phone,
            requiredMessage: 'phone_required'.tr(),
            invalidMessage: 'invalid_phone'.tr(),
          ),
          if (_signup) ...[
            const SizedBox(height: 16),
            TermsCheckbox(
              accepted: _terms,
              hasError: _invalid.contains('terms'),
              onToggle: () => setState(() => _terms = !_terms),
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
