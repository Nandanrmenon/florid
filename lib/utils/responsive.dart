import 'package:flutter/material.dart';

class Responsive {
  static const double largeWidth = 600;

  static Size deviceSize(BuildContext context) {
    return MediaQuery.sizeOf(context);
  }

  static bool isLargeWidth(double width) {
    return width >= largeWidth;
  }
}

extension ResponsiveContext on BuildContext {
  Size get deviceSize => Responsive.deviceSize(this);

  bool get isLargeScreen => deviceSize.width >= Responsive.largeWidth;

  bool get isSmallScreen => deviceSize.width < Responsive.largeWidth;
}
