import '../../../../core/utils/json.dart';
import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id,
    super.label,
    super.recipientName,
    super.phone,
    super.country,
    super.city,
    super.area,
    super.block,
    super.street,
    super.building,
    super.floor,
    super.apartment,
    super.additionalDirections,
    super.isDefault,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: jsonId(json['id']) ?? '',
        label: _text(json['label']) ?? '',
        recipientName: _text(json['recipient_name']) ?? '',
        phone: _text(json['phone']) ?? '',
        country: _text(json['country']),
        city: _text(json['city']) ?? '',
        area: _text(json['area']) ?? '',
        block: _text(json['block']),
        street: _text(json['street']) ?? '',
        building: _text(json['building']),
        floor: _text(json['floor']),
        apartment: _text(json['apartment']),
        additionalDirections: _text(json['additional_directions']),
        isDefault: jsonBool(json['is_default']) ?? false,
      );

  static List<Address> listFrom(Object? value) => [
        for (final item in jsonList(value)) AddressModel.fromJson(item),
      ].where((address) => address.id.isNotEmpty).toList();

  static String? _text(Object? value) {
    final text = jsonString(value)?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}

extension AddressRequest on AddressParams {
  Map<String, dynamic> toJson() => {
        'label': label.trim(),
        'recipient_name': recipientName.trim(),
        'phone': phone.trim(),
        'country': country,
        'city': city.trim(),
        'area': area.trim(),
        'block': _blankToNull(block),
        'street': street.trim(),
        'building': _blankToNull(building),
        'floor': _blankToNull(floor),
        'apartment': _blankToNull(apartment),
        'additional_directions': _blankToNull(additionalDirections),
        'is_default': isDefault,
      };

  static String? _blankToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
