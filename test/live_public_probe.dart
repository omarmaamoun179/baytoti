import 'package:baytoti/core/network/api_endpoints.dart';
import 'package:baytoti/core/network/api_response.dart';
import 'package:baytoti/features/catalog/data/models/catalog_models.dart';
import 'package:baytoti/features/home/data/models/home_feed_model.dart';
import 'package:baytoti/features/location/data/models/location_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ApiResponse> _get(String url) async => checkedResponse(
      await Dio().get<dynamic>(
        url,
        options: Options(
          validateStatus: (_) => true,
          headers: {'Accept': 'application/json'},
        ),
      ),
    );

void main() {
  test('the live home parses into every section the app shows', () async {
    final feed = HomeFeedModel.fromJson((await _get(ApiEndPoint.home)).json);

    expect(feed.banners, isNotEmpty);
    expect(feed.categories, isNotEmpty);
    expect(feed.trustedStores, isNotEmpty);
    expect(
      feed.trustedStores.every((s) => s.family.slug.isNotEmpty),
      isTrue,
    );
  });

  test('the live categories carry a slug and a name', () async {
    final categories =
        CategoryModel.listFrom((await _get(ApiEndPoint.categories)).json['data']);

    expect(categories, isNotEmpty);
    expect(categories.every((c) => c.slug.isNotEmpty && c.name.isNotEmpty), isTrue);
  });

  test('every live country has governorates', () async {
    final countries =
        CountryModel.listFrom((await _get(ApiEndPoint.countries)).json['data']);
    expect(countries, isNotEmpty);

    for (final country in countries) {
      final governorates = GovernorateModel.listFrom(
        (await _get(ApiEndPoint.countryGovernorates(country.id))).json['data'],
      );
      expect(governorates, isNotEmpty, reason: country.code);
    }
  });
}
