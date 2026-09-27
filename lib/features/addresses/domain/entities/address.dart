import 'package:equatable/equatable.dart';

class Address extends Equatable {
  static const int labelMaxLength = 50;
  static const int recipientNameMaxLength = 150;
  static const int phoneMaxLength = 30;
  static const int cityMaxLength = 100;
  static const int areaMaxLength = 100;
  static const int blockMaxLength = 50;
  static const int streetMaxLength = 150;
  static const int buildingMaxLength = 100;
  static const int floorMaxLength = 50;
  static const int apartmentMaxLength = 50;

  static const String kuwait = 'Kuwait';
  static const String egypt = 'Egypt';

  final String id;
  final String label;
  final String recipientName;
  final String phone;
  final String? country;
  final String city;
  final String area;
  final String? block;
  final String street;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? additionalDirections;
  final bool isDefault;

  const Address({
    required this.id,
    this.label = '',
    this.recipientName = '',
    this.phone = '',
    this.country,
    this.city = '',
    this.area = '',
    this.block,
    this.street = '',
    this.building,
    this.floor,
    this.apartment,
    this.additionalDirections,
    this.isDefault = false,
  });

  String get line {
    final parts = [area, block, street, building, floor, apartment]
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join(', ');
    return parts.isEmpty ? city : parts;
  }

  String get title => label.trim().isEmpty ? city : label;

  @override
  List<Object?> get props => [
        id,
        label,
        recipientName,
        phone,
        country,
        city,
        area,
        block,
        street,
        building,
        floor,
        apartment,
        additionalDirections,
        isDefault,
      ];
}

class AddressParams extends Equatable {
  final String label;
  final String recipientName;
  final String phone;
  final String country;
  final String city;
  final String area;
  final String? block;
  final String street;
  final String? building;
  final String? floor;
  final String? apartment;
  final String? additionalDirections;
  final bool isDefault;

  const AddressParams({
    required this.label,
    required this.recipientName,
    required this.phone,
    this.country = Address.kuwait,
    required this.city,
    required this.area,
    this.block,
    required this.street,
    this.building,
    this.floor,
    this.apartment,
    this.additionalDirections,
    this.isDefault = false,
  });

  @override
  List<Object?> get props => [
        label,
        recipientName,
        phone,
        country,
        city,
        area,
        block,
        street,
        building,
        floor,
        apartment,
        additionalDirections,
        isDefault,
      ];
}
