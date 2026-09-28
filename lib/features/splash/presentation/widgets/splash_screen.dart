import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/utils/app_strings.dart';
import 'splash_mark.dart';
import 'splash_timeline.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onDone;

  const SplashScreen({super.key, required this.onDone});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(vsync: this, duration: SplashTimeline.length)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _leave();
      })
      ..forward();
    FlutterNativeSplash.remove();
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _leave() {
    if (_left) return;
    _left = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _leave,
        child: Material(
          color: p.accent,
          child: SizedBox.expand(
            child: AnimatedBuilder(
              animation: _clock,
              builder: (context, _) => _buildFrame(
                p,
                _clock.value * SplashTimeline.length.inMilliseconds / 1000,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrame(AppPalette p, double seconds) {
    final white = p.onAccent;

    return Stack(
      alignment: Alignment.center,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 190,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  _ring(white, seconds, 1.0),
                  _ring(white, seconds, 2.3),
                  SplashMark(seconds: seconds, stroke: white, bubble: p.amber),
                ],
              ),
            ),
            _fadeUp(
              seconds,
              1.6,
              top: 6,
              Text(
                'بيتوتي',
                style: AppStrings.w800(46, 1)
                    .copyWith(leadingDistribution: TextLeadingDistribution.even)
                    .c(white),
              ),
            ),
            _fadeUp(
              seconds,
              1.85,
              top: 12,
              Text(
                'BAYTOUTI',
                style: AppStrings.w800(10, 1)
                    .spaced(10 * .34)
                    .c(white.withValues(alpha: .7)),
              ),
            ),
            _fadeUp(
              seconds,
              2.1,
              top: 18,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'splash_tagline'.tr(),
                  textAlign: TextAlign.center,
                  style: AppStrings.w500(13, 1.6)
                      .c(white.withValues(alpha: .88)),
                ),
              ),
            ),
          ],
        ),
        Positioned(bottom: 70, child: _progress(p, seconds)),
      ],
    );
  }

  Widget _ring(Color white, double seconds, double start) {
    if (seconds < start) return const SizedBox.shrink();

    final phase = ((seconds - start) % SplashTimeline.ringFor) /
        SplashTimeline.ringFor;
    final opacity = phase < .3
        ? Curves.easeOut.transform(phase / .3)
        : 1 - Curves.easeOut.transform((phase - .3) / .7);

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: .55 + (1.6 - .55) * Curves.easeOut.transform(phase),
        child: Container(
          width: 190,
          height: 190,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: white.withValues(alpha: .16), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _fadeUp(
    double seconds,
    double start,
    Widget child, {
    required double top,
  }) {
    final shown = SplashTimeline.eased(
      SplashTimeline.fadeUp,
      seconds,
      start,
      SplashTimeline.fadeFor,
    );

    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Opacity(
        opacity: shown.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - shown)),
          child: child,
        ),
      ),
    );
  }

  Widget _progress(AppPalette p, double seconds) {
    final filled = SplashTimeline.progress(
      seconds,
      SplashTimeline.barFrom,
      SplashTimeline.barFor,
    );
    final radius = BorderRadius.circular(3);

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: 120,
        height: 3,
        color: p.onAccent.withValues(alpha: .18),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: filled,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: p.amber, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}
