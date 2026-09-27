import 'package:flutter/widgets.dart';

class PagedScrollListener extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onEndOfPage;
  final Widget child;
  final double threshold;

  const PagedScrollListener({
    super.key,
    required this.isLoading,
    required this.onEndOfPage,
    required this.child,
    this.threshold = 320,
  });

  @override
  State<PagedScrollListener> createState() => _PagedScrollListenerState();
}

class _PagedScrollListenerState extends State<PagedScrollListener> {
  bool _armed = true;

  @override
  void didUpdateWidget(PagedScrollListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading && !widget.isLoading) _armed = true;
  }

  bool _onNotification(Notification notification) {
    final ScrollMetrics metrics;
    if (notification is ScrollNotification) {
      metrics = notification.metrics;
    } else if (notification is ScrollMetricsNotification) {
      metrics = notification.metrics;
    } else {
      return false;
    }

    if (metrics.axis != Axis.vertical) return false;
    if (!_armed || widget.isLoading) return false;
    if (metrics.extentAfter > widget.threshold) return false;

    _armed = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onEndOfPage();
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<Notification>(
      onNotification: _onNotification,
      child: widget.child,
    );
  }
}
