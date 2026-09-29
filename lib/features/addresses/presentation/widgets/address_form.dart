import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/market.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/utils/validators/validator_logic.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/phone_text_form_field.dart';
import '../../domain/entities/address.dart';
import 'address_country_picker.dart';
import 'address_default_toggle.dart';
import 'address_field.dart';

class AddressForm extends StatefulWidget {
  static const Set<String> fields = {
    'label',
    'recipient_name',
    'phone',
    'country',
    'city',
    'area',
    'block',
    'street',
    'building',
    'floor',
    'apartment',
    'additional_directions',
  };

  final Address? initial;
  final bool isSaving;
  final Map<String, String> fieldErrors;
  final ValueChanged<String> onFieldChanged;
  final ValueChanged<AddressParams> onSubmit;

  const AddressForm({
    super.key,
    this.initial,
    required this.isSaving,
    required this.fieldErrors,
    required this.onFieldChanged,
    required this.onSubmit,
  });

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  static const List<String> _required = [
    'label',
    'recipient_name',
    'city',
    'area',
    'street',
  ];

  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _text;
  late final TextEditingController _phone;
  late final Market _phoneMarket;
  String? _e164;
  late String _country;
  late bool _isDefault;
  Map<String, String> _local = const {};

  bool get _wasDefault => widget.initial?.isDefault ?? false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _text = {
      'label': TextEditingController(text: initial?.label),
      'recipient_name': TextEditingController(text: initial?.recipientName),
      'city': TextEditingController(text: initial?.city),
      'area': TextEditingController(text: initial?.area),
      'block': TextEditingController(text: initial?.block),
      'street': TextEditingController(text: initial?.street),
      'building': TextEditingController(text: initial?.building),
      'floor': TextEditingController(text: initial?.floor),
      'apartment': TextEditingController(text: initial?.apartment),
      'additional_directions':
          TextEditingController(text: initial?.additionalDirections),
    };

    final digits = digitsOnly(initial?.phone);
    final market = Market.ofPhone(digits);
    _phoneMarket = market ?? Money.market;
    _phone = TextEditingController(
      text: market == null
          ? digits
          : digits.substring(market.dialCode.length - 1),
    );

    _country = switch (initial?.country) {
      Address.kuwait => Address.kuwait,
      Address.egypt => Address.egypt,
      _ => Money.market == Market.eg ? Address.egypt : Address.kuwait,
    };
    _isDefault = _wasDefault;
  }

  @override
  void dispose() {
    for (final controller in _text.values) {
      controller.dispose();
    }
    _phone.dispose();
    super.dispose();
  }

  String? _errorFor(String key) => _local[key] ?? widget.fieldErrors[key];

  void _changed(String key) {
    if (_local.containsKey(key)) {
      setState(() => _local = {..._local}..remove(key));
    }
    widget.onFieldChanged(key);
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    final phoneValid = _formKey.currentState?.validate() ?? true;
    final local = {
      for (final key in _required)
        if (_text[key]!.text.trim().isEmpty) key: 'field_required'.tr(),
    };
    setState(() => _local = local);
    if (local.isNotEmpty || !phoneValid) return;

    String value(String key) => _text[key]!.text.trim();
    String? optional(String key) => value(key).isEmpty ? null : value(key);

    widget.onSubmit(AddressParams(
      label: value('label'),
      recipientName: value('recipient_name'),
      phone: _e164 ?? widget.initial?.phone ?? '',
      country: _country,
      city: value('city'),
      area: value('area'),
      block: optional('block'),
      street: value('street'),
      building: optional('building'),
      floor: optional('floor'),
      apartment: optional('apartment'),
      additionalDirections: optional('additional_directions'),
      isDefault: _wasDefault || _isDefault,
    ));
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    final phoneError = widget.fieldErrors['phone'];

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field('label', 'address_field_label', Address.labelMaxLength,
                hint: 'address_label_hint'.tr()),
            gap,
            _field(
              'recipient_name',
              'address_field_recipient',
              Address.recipientNameMaxLength,
            ),
            gap,
            PhoneTextFormField(
              label: 'address_field_phone'.tr(),
              hintText:
                  _phoneMarket == Market.eg ? '100 123 4567' : '5150 2244',
              controller: _phone,
              initialIsoCode: _phoneMarket.iso,
              initialNumber: widget.initial?.phone,
              requiredMessage: 'phone_required'.tr(),
              invalidMessage: 'invalid_phone'.tr(),
              onInputChanged: (number) {
                _e164 = number.phoneNumber;
                widget.onFieldChanged('phone');
              },
            ),
            if (phoneError != null) FieldErrorText(phoneError),
            gap,
            AddressCountryPicker(
              value: _country,
              error: _errorFor('country'),
              onChanged: (country) {
                setState(() => _country = country);
                _changed('country');
              },
            ),
            gap,
            _field('city', 'address_field_city', Address.cityMaxLength),
            gap,
            _row([
              _field('area', 'address_field_area', Address.areaMaxLength),
              _field('block', 'address_field_block', Address.blockMaxLength),
            ]),
            gap,
            _field('street', 'address_field_street', Address.streetMaxLength),
            gap,
            _row([
              _field(
                'building',
                'address_field_building',
                Address.buildingMaxLength,
              ),
              _field('floor', 'address_field_floor', Address.floorMaxLength),
              _field(
                'apartment',
                'address_field_apartment',
                Address.apartmentMaxLength,
              ),
            ]),
            gap,
            AddressField(
              label: 'address_field_directions'.tr(),
              controller: _text['additional_directions']!,
              hint: 'address_directions_hint'.tr(),
              multiline: true,
              error: _errorFor('additional_directions'),
              onChanged: (_) => _changed('additional_directions'),
            ),
            if (!_wasDefault) ...[
              const SizedBox(height: 18),
              AddressDefaultToggle(
                label: 'address_set_default'.tr(),
                value: _isDefault,
                onToggle: () => setState(() => _isDefault = !_isDefault),
              ),
            ],
            const SizedBox(height: 26),
            AppButton(
              label: 'address_save'.tr(),
              isLoading: widget.isSaving,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String key, String labelKey, int maxLength, {String? hint}) =>
      AddressField(
        label: labelKey.tr(),
        controller: _text[key]!,
        hint: hint,
        maxLength: maxLength,
        error: _errorFor(key),
        onChanged: (_) => _changed(key),
      );

  Widget _row(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: children[i]),
          ],
        ],
      );
}
