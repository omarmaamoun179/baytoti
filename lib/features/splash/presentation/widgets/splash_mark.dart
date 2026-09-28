import 'package:flutter/material.dart';

import 'splash_timeline.dart';

class SplashMark extends StatelessWidget {
  static const Color leaf = Color(0xFFCFE3D7);

  final double seconds;
  final Color stroke;
  final Color bubble;

  const SplashMark({
    super.key,
    required this.seconds,
    required this.stroke,
    required this.bubble,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(112, 100),
      painter: SplashMarkPainter(
        seconds: seconds,
        stroke: stroke,
        leaf: leaf,
        bubble: bubble,
      ),
    );
  }
}

class SplashMarkPainter extends CustomPainter {
  static const Size viewBox = Size(96, 86);

  final double seconds;
  final Color stroke;
  final Color leaf;
  final Color bubble;

  SplashMarkPainter({
    required this.seconds,
    required this.stroke,
    required this.leaf,
    required this.bubble,
  });

  static final Path roof = Path()
    ..moveTo(14, 40)
    ..lineTo(48, 13)
    ..lineTo(82, 40);

  static final Path walls = Path()
    ..moveTo(21, 38)
    ..lineTo(21, 70)
    ..lineTo(75, 70)
    ..lineTo(75, 38);

  static final Path door = Path()
    ..moveTo(40, 70)
    ..lineTo(40, 54)
    ..lineTo(56, 54)
    ..lineTo(56, 70);

  static final Path leafShape = Path()
    ..moveTo(44, 30)
    ..cubicTo(44, 23, 49, 18, 55, 17)
    ..cubicTo(54, 25, 50, 29, 44, 30)
    ..close();

  static final Path bubbleShape = Path()
    ..moveTo(62, 24)
    ..cubicTo(65.6, 24, 68, 26.4, 68, 29.6)
    ..cubicTo(68, 33, 65.2, 36, 61.6, 36)
    ..cubicTo(60.4, 36, 59.2, 35.6, 58.4, 35)
    ..lineTo(55, 36.4)
    ..lineTo(56.2, 33.2)
    ..cubicTo(55.6, 32.2, 55.2, 31, 55.2, 29.8)
    ..cubicTo(55.2, 26.6, 58.4, 24, 62, 24)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = [
      size.width / viewBox.width,
      size.height / viewBox.height,
    ].reduce((a, b) => a < b ? a : b);
    canvas
      ..save()
      ..translate(
        (size.width - viewBox.width * scale) / 2,
        (size.height - viewBox.height * scale) / 2,
      )
      ..scale(scale);

    _draw(canvas, roof, start: .25, width: 5.5);
    _draw(canvas, walls, start: .55, width: 5.5);
    _draw(canvas, door, start: .85, width: 5);
    _pop(canvas, leafShape, leaf, start: 1.25);
    _pop(canvas, bubbleShape, bubble, start: 1.45);

    canvas.restore();
  }

  void _draw(
    Canvas canvas,
    Path path, {
    required double start,
    required double width,
  }) {
    final drawn = SplashTimeline.eased(
      SplashTimeline.draw,
      seconds,
      start,
      SplashTimeline.drawFor,
    );
    if (drawn <= 0) return;

    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * drawn), paint);
    }
  }

  void _pop(Canvas canvas, Path path, Color color, {required double start}) {
    final scale = SplashTimeline.eased(
      SplashTimeline.pop,
      seconds,
      start,
      SplashTimeline.popFor,
    );
    if (scale <= 0) return;

    final center = path.getBounds().center;
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(scale)
      ..translate(-center.dx, -center.dy)
      ..drawPath(path, Paint()..color = color)
      ..restore();
  }

  @override
  bool shouldRepaint(SplashMarkPainter old) =>
      old.seconds != seconds ||
      old.stroke != stroke ||
      old.leaf != leaf ||
      old.bubble != bubble;
}
