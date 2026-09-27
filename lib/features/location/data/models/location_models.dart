import 'dart:convert';

import '../../../../core/utils/json.dart';
import '../../domain/entities/location.dart';

class CountryModel extends Country {
  const CountryModel({
    required super.id,
    required super.name,
    required super.code,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
        id: jsonId(json['id']) ?? '',
        name: jsonString(json['name']) ?? '',
        code: (jsonString(json['code']) ?? '').toUpperCase(),
      );

  static List<Country> listFrom(Object? value) =>
      [for (final item in jsonList(value)) CountryModel.fromJson(item)];
}

class GovernorateModel extends Governorate {
  const GovernorateModel({
    required super.id,
    required super.countryId,
    required super.name,
  });

  factory GovernorateModel.fromJson(Map<String, dynamic> json) =>
      GovernorateModel(
        id: jsonId(json['id']) ?? '',
        countryId: jsonId(json['country_id']) ?? '',
        name: jsonString(json['name']) ?? '',
      );

  static List<Governorate> listFrom(Object? value) =>
      [for (final item in jsonList(value)) GovernorateModel.fromJson(item)];
}

class LocationContextModel extends LocationContext {
  const LocationContextModel({
    super.countryId,
    super.governorateId,
    super.countryCode,
  });

  static const List<String> _countryKeys = [
    'selected_country_id',
    'resolved_country_id',
    'country_id',
    'selected_country',
    'resolved_country',
    'country',
  ];

  static const List<String> _governorateKeys = [
    'selected_governorate_id',
    'resolved_governorate_id',
    'governorate_id',
    'selected_governorate',
    'resolved_governorate',
    'governorate',
  ];

  factory LocationContextModel.fromJson(Map<String, dynamic> json) {
    final source = jsonMapOrNull(json['context']) ?? json;

    return LocationContextModel(
      countryId: _first(source, _countryKeys, jsonId),
      governorateId: _first(source, _governorateKeys, jsonId),
      countryCode: _first(
        source,
        _countryKeys,
        (value) => jsonString(jsonMap(value)['code'])?.toUpperCase(),
      ),
    );
  }

  factory LocationContextModel.decode(String source) =>
      LocationContextModel.fromJson(jsonMap(jsonDecode(source)));

  static String encode(LocationContext context) => jsonEncode({
        'country_id': context.countryId,
        'governorate_id': context.governorateId,
        'country': {'code': context.countryCode},
      });

  static String? _first(
    Map<String, dynamic> json,
    List<String> keys,
    String? Function(Object?) read,
  ) {
    for (final key in keys) {
      final value = read(json[key]);
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }
}
