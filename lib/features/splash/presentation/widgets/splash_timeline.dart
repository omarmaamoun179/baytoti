import 'package:flutter/animation.dart';

class SplashTimeline {
  SplashTimeline._();

  static const Duration length = Duration(milliseconds: 3500);

  static const Cubic draw = Cubic(.6, 0, .2, 1);
  static const Cubic pop = Cubic(.3, 1.6, .5, 1);
  static const Cubic fadeUp = Cubic(.2, .7, .2, 1);

  static const double drawFor = .9;
  static const double popFor = .55;
  static const double fadeFor = .7;
  static const double ringFor = 2.6;
  static const double barFrom = .2;
  static const double barFor = 3;

  static double progress(double seconds, double start, double duration) =>
      ((seconds - start) / duration).clamp(0.0, 1.0);

  static double eased(Curve curve, double seconds, double start, double length) {
    final t = progress(seconds, start, length);
    return t == 0 ? 0 : curve.transform(t);
  }
}
