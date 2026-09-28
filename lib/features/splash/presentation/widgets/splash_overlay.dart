import 'package:flutter/material.dart';

import 'splash_screen.dart';

class SplashOverlay extends StatefulWidget {
  static const Duration fadeOut = Duration(milliseconds: 280);

  final Widget child;

  const SplashOverlay({super.key, required this.child});

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay> {
  bool _leaving = false;
  bool _gone = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(excluding: !_gone, child: widget.child),
        if (!_gone)
          IgnorePointer(
            ignoring: _leaving,
            child: AnimatedOpacity(
              opacity: _leaving ? 0 : 1,
              duration: SplashOverlay.fadeOut,
              onEnd: () => setState(() => _gone = true),
              child: SplashScreen(
                onDone: () => setState(() => _leaving = true),
              ),
            ),
          ),
      ],
    );
  }
}
