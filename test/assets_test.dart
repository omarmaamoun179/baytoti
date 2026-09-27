import 'dart:io';

import 'package:baytoti/core/utils/app_assets.dart';
import 'package:baytoti/core/widgets/network_photo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final pubspec = File('pubspec.yaml').readAsStringSync();

  test('the welcome hero ships with the app', () {
    expect(File(AppAssets.welcomeHero).existsSync(), isTrue);
    expect(pubspec, contains('- assets/images/'));
    expect(NetworkPhoto.isBundled(AppAssets.welcomeHero), isTrue);
  });

  test('a server URL is not mistaken for a bundled photo', () {
    expect(
      NetworkPhoto.isBundled('https://images.unsplash.com/photo-1.jpg'),
      isFalse,
    );
  });
}
