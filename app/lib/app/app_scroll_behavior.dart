import 'package:flutter/material.dart';

/// Global scroll behavior: removes the overscroll glow / bounce everywhere and
/// clamps scrolling to the content bounds.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // No glow / stretch indicator.
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();
}
