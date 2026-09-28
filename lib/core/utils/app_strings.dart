import 'package:flutter/material.dart';

import 'size_config.dart';

class AppStrings {
  AppStrings._();

  static const String fontFamily = 'Archivo';
  static const List<String> fontFamilyFallback = ['IBMPlexSansArabic'];

  static TextStyle w800(double size, [double? height]) =>
      _s(size, FontWeight.w800, height);

  static TextStyle w600(double size, [double? height]) =>
      _s(size, FontWeight.w600, height);

  static TextStyle w500(double size, [double? height]) =>
      _s(size, FontWeight.w500, height);

  static TextStyle w400(double size, [double? height]) =>
      _s(size, FontWeight.w400, height);

  static TextStyle _s(double size, FontWeight weight, double? height) =>
      TextStyle(
        fontFamily: fontFamily,
        fontFamilyFallback: fontFamilyFallback,
        fontSize: SizeConfig.sp(size),
        fontWeight: weight,
        height: height,
      );
}

extension TextStyleColor on TextStyle {
  TextStyle c(Color color) => copyWith(color: color);

  TextStyle lh(double height) => copyWith(height: height);

  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);

  TextStyle spaced(double letterSpacing) =>
      copyWith(letterSpacing: letterSpacing);
}
