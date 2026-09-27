import 'package:flutter_screenutil/flutter_screenutil.dart';

class SizeConfig {
  SizeConfig._();

  static const double designWidth = 402;
  static const double designHeight = 874;

  static double get screenWidth => 1.sw;
  static double get screenHeight => 1.sh;

  static double w(double width) => width.w;

  static double h(double height) => height.h;

  static double sp(double size) => size.sp;

  static double r(double radius) => radius.r;
}
