import 'package:equatable/equatable.dart';

class Country extends Equatable {
  final String id;
  final String name;
  final String code;

  const Country({required this.id, required this.name, required this.code});

  @override
  List<Object?> get props => [id, name, code];
}

class Governorate extends Equatable {
  final String id;
  final String countryId;
  final String name;

  const Governorate({
    required this.id,
    required this.countryId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, countryId, name];
}

class LocationContext extends Equatable {
  final String? countryId;
  final String? governorateId;
  final String? countryCode;

  const LocationContext({this.countryId, this.governorateId, this.countryCode});

  static const LocationContext none = LocationContext();

  bool get isSet => countryId != null && governorateId != null;

  LocationContext withCode(String? code) => LocationContext(
        countryId: countryId,
        governorateId: governorateId,
        countryCode: code ?? countryCode,
      );

  @override
  List<Object?> get props => [countryId, governorateId, countryCode];
}
