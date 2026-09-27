import 'dart:io';

import 'package:baytoti/core/utils/app_assets.dart';
import 'package:baytoti/core/widgets/network_photo.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_backend.dart';
import 'package:baytoti/features/catalog/data/fixtures/fixture_data.dart';
import 'package:baytoti/features/catalog/data/models/catalog_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  void expectBundled(String path) {
    expect(File(path).existsSync(), isTrue, reason: '$path is missing');
    final folder = path.substring(0, path.lastIndexOf('/') + 1);
    expect(pubspec, contains('- $folder'), reason: '$folder is not bundled');
  }

  test('the welcome hero ships with the app', () {
    expectBundled(AppAssets.welcomeHero);
  });

  test('every fixture product and family has its photos', () {
    for (final product in FixtureData.products) {
      expectBundled(AppAssets.productPhoto(product.id));
    }
    for (final family in FixtureData.families) {
      expectBundled(AppAssets.familyPhoto(family.id));
      expectBundled(AppAssets.familyAvatar(family.id));
    }
  });

  test('the fixture backend answers with bundled photos', () {
    final products = ProductSummaryModel.listFrom(
      FixtureBackend().home('ar')['best_sellers'],
    );

    for (final product in products) {
      final url = product.images.single.url;
      expect(NetworkPhoto.isBundled(url), isTrue);
      expectBundled(url);
    }
  });

  test('a server URL is not mistaken for a bundled photo', () {
    expect(NetworkPhoto.isBundled('https://cdn.baytouti.com/p1.jpg'), isFalse);
  });
}
