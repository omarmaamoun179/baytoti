import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'size_config.dart';

class ScreenUtilScope extends StatefulWidget {
  final Widget child;

  const ScreenUtilScope({super.key, required this.child});

  @override
  State<ScreenUtilScope> createState() => _ScreenUtilScopeState();
}

class _ScreenUtilScopeState extends State<ScreenUtilScope> {
  static const Size _designSize = Size(
    SizeConfig.designWidth,
    SizeConfig.designHeight,
  );

  Size? _lastSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final size = MediaQuery.sizeOf(context);

    if (_lastSize != null && _lastSize != size) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) (context as Element).visitChildren(_markDirty);
      });
    }
    _lastSize = size;
  }

  void _markDirty(Element element) {
    element.markNeedsBuild();
    element.visitChildren(_markDirty);
  }

  static double _capAtDesignSize(num fontSize, ScreenUtil instance) =>
      fontSize *
      math.min(1, math.min(instance.scaleWidth, instance.scaleHeight));

  @override
  Widget build(BuildContext context) {
    ScreenUtil.configure(
      data: MediaQuery.of(context),
      designSize: _designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      fontSizeResolver: _capAtDesignSize,
    );
    return widget.child;
  }
}
