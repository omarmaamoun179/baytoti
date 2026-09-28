import 'package:baytoti/core/theme/app_theme.dart';
import 'package:baytoti/core/utils/screen_util_scope.dart';
import 'package:baytoti/features/splash/presentation/widgets/splash_mark.dart';
import 'package:baytoti/features/splash/presentation/widgets/splash_overlay.dart';
import 'package:baytoti/features/splash/presentation/widgets/splash_screen.dart';
import 'package:baytoti/features/splash/presentation/widgets/splash_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => ScreenUtilScope(
      child: Builder(
        builder: (_) => MaterialApp(theme: AppTheme.light, home: child),
      ),
    );

double _opacityOf(WidgetTester tester, String text) => tester
    .widget<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)).first,
    )
    .opacity;

Future<void> _at(WidgetTester tester, double seconds) =>
    tester.pump(Duration(milliseconds: (seconds * 1000).round()));

void main() {
  group('the timeline', () {
    test('each stroke draws in its own window', () {
      double roof(double s) =>
          SplashTimeline.eased(SplashTimeline.draw, s, .25, .9);

      expect(roof(0), 0);
      expect(roof(.25), 0);
      expect(roof(.7), inExclusiveRange(0, 1));
      expect(roof(1.2), 1);
      expect(roof(3), 1);
    });

    test('a pop overshoots before it settles, as the design bounces', () {
      final samples = [
        for (var s = 1.25; s <= 1.8; s += .02)
          SplashTimeline.eased(SplashTimeline.pop, s, 1.25, .55),
      ];

      expect(samples.first, 0);
      expect(samples.reduce((a, b) => a > b ? a : b), greaterThan(1));
      expect(SplashTimeline.eased(SplashTimeline.pop, 2, 1.25, .55), 1);
    });

    test('the whole splash lasts three and a half seconds', () {
      expect(SplashTimeline.length, const Duration(milliseconds: 3500));
    });
  });

  group('the splash screen', () {
    testWidgets('the name, the wordmark and the tagline fade up in turn',
        (tester) async {
      await tester.pumpWidget(_app(SplashScreen(onDone: () {})));

      expect(_opacityOf(tester, 'بيتوتي'), 0);
      expect(_opacityOf(tester, 'BAYTOUTI'), 0);
      expect(_opacityOf(tester, 'splash_tagline'), 0);

      await _at(tester, 1.9);
      expect(_opacityOf(tester, 'بيتوتي'), inExclusiveRange(0, 1));
      expect(_opacityOf(tester, 'splash_tagline'), 0);

      await _at(tester, 1.1);
      expect(_opacityOf(tester, 'بيتوتي'), 1);
      expect(_opacityOf(tester, 'BAYTOUTI'), 1);
      expect(_opacityOf(tester, 'splash_tagline'), 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the bar fills over three seconds after a short wait',
        (tester) async {
      await tester.pumpWidget(_app(SplashScreen(onDone: () {})));
      double filled() => tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;

      expect(filled(), 0);
      await _at(tester, 1.7);
      expect(filled(), closeTo(.5, .01));
      await _at(tester, 1.6);
      expect(filled(), 1);
    });

    testWidgets('the mark is painted with white strokes and an amber bubble',
        (tester) async {
      await tester.pumpWidget(_app(SplashScreen(onDone: () {})));
      await _at(tester, 2);

      final mark = tester.widget<SplashMark>(find.byType(SplashMark));
      expect(mark.stroke, AppTheme.light.colorScheme.onPrimary);
      expect(mark.bubble, AppTheme.light.colorScheme.secondary);
      expect(mark.seconds, closeTo(2, .02));
    });

    testWidgets('the status bar turns light over the green', (tester) async {
      await tester.pumpWidget(_app(SplashScreen(onDone: () {})));

      final region = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(SplashScreen),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ),
      );
      expect(region.value, SystemUiOverlayStyle.light);
    });

    testWidgets('it reports leaving once, whether tapped or timed out',
        (tester) async {
      var left = 0;
      await tester.pumpWidget(_app(SplashScreen(onDone: () => left++)));

      await tester.tap(find.byType(SplashScreen));
      await tester.tap(find.byType(SplashScreen));
      await _at(tester, 3.6);

      expect(left, 1);
    });
  });

  group('the overlay', () {
    late int appTaps;

    Widget overlay() => SplashOverlay(
          child: Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => appTaps++,
                child: const Text('the app'),
              ),
            ),
          ),
        );

    setUp(() => appTaps = 0);

    testWidgets('covers the app, then steps aside after three and a half '
        'seconds', (tester) async {
      await tester.pumpWidget(_app(overlay()));

      expect(find.byType(SplashScreen), findsOne);
      await tester.tap(find.text('the app'), warnIfMissed: false);
      expect(appTaps, 0);

      await _at(tester, 3.4);
      expect(find.byType(SplashScreen), findsOne);

      await _at(tester, .1);
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      await tester.tap(find.text('the app'));
      expect(appTaps, 1);
    });

    testWidgets('a tap skips straight to the app', (tester) async {
      await tester.pumpWidget(_app(overlay()));
      await _at(tester, .5);

      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsNothing);
      expect(appTaps, 0);
    });

    testWidgets('screen readers only reach the app once the splash is gone',
        (tester) async {
      await tester.pumpWidget(_app(overlay()));
      bool hidden() => tester
          .widget<ExcludeSemantics>(
            find
                .ancestor(
                  of: find.text('the app'),
                  matching: find.byType(ExcludeSemantics),
                )
                .last,
          )
          .excluding;

      expect(hidden(), isTrue);

      await _at(tester, 3.5);
      await tester.pumpAndSettle();

      expect(hidden(), isFalse);
    });
  });
}
