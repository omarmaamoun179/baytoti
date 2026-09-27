class AppAssets {
  AppAssets._();

  static const String _images = 'assets/images';
  static const String _catalog = '$_images/catalog';

  static const String welcomeHero = '$_images/welcome_hero.jpg';

  static String productPhoto(String productId) => '$_catalog/$productId.jpg';

  static String familyPhoto(String familyId) => '$_catalog/$familyId.jpg';

  static String familyAvatar(String familyId) =>
      '$_catalog/${familyId}_avatar.jpg';
}
