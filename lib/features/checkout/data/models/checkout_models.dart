import '../../../../core/utils/json.dart';
import '../../domain/entities/checkout.dart';

class CheckoutAddressModel extends CheckoutAddress {
  static const List<String> _lineKeys = [
    'area',
    'block',
    'street',
    'building',
    'floor',
    'apartment',
  ];

  const CheckoutAddressModel({
    required super.id,
    required super.label,
    required super.line,
    super.isDefault,
  });

  factory CheckoutAddressModel.fromJson(Map<String, dynamic> json) {
    final city =
        _text(json['city']) ?? _text(jsonMap(json['governorate'])['name']);
    final line = [
      for (final key in _lineKeys) ?_text(json[key]),
    ].join(', ');

    return CheckoutAddressModel(
      id: jsonId(json['id']) ?? '',
      label: _text(json['label']) ?? city ?? '',
      line: line.isEmpty ? city ?? '' : line,
      isDefault: jsonBool(json['is_default']) ?? false,
    );
  }

  static List<CheckoutAddress> listFrom(Object? value) => [
        for (final item in jsonList(value)) CheckoutAddressModel.fromJson(item),
      ].where((address) => address.id.isNotEmpty).toList();

  static String? _text(Object? value) {
    final text = jsonString(value)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

extension PlaceOrderRequest on PlaceOrderParams {
  Map<String, dynamic> toJson() {
    final notes = this.notes?.trim();

    return {
      'address_id': int.tryParse(addressId) ?? addressId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
  }
}
