import 'package:flutter/material.dart';

/// Material You design system recommend screen size
/// Desktop/Expanded screen: 840dp
/// Tablet/Medium screen: 600dp
/// Mobile/Compact screen: 360dp
const double largeScreenSize = 1200;
const double expandedScreenSize = 840;
const double mediumScreenSize = 600;
const double compactScreenSize = 360;

BoxDecoration getContainerDecoration(BuildContext context) {
  return BoxDecoration(
    border: Border.all(
      color: getBorderColor(context),
      width: 2,
    ),
    borderRadius: BorderRadius.circular(16),
    color: Theme.of(context).colorScheme.surface,
  );
}

RoundedRectangleBorder getIndicatorShape(BuildContext context) {
  return const RoundedRectangleBorder(
    borderRadius: BorderRadius.horizontal(
      right: Radius.circular(16),
      left: Radius.circular(16),
    ),
  );
}

Color? getSEGULBackgroundColor(BuildContext context) {
  return Color.lerp(Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface, 0.9);
}

Color getIndicatorColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withAlpha(80);
}

Color getIconColor(BuildContext context) {
  return Theme.of(context).colorScheme.tertiary.withAlpha(120);
}

Color getBorderColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withAlpha(40);
}

bool isPhoneScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < mediumScreenSize;
}

// Large screen is defined as screen width >= 840 dp
// Based on Material Design guidelines for expanded screen.
// https://material.io/blog/material-you-large-screens
bool isTabletScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= expandedScreenSize;
}

bool isDesktopScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= largeScreenSize;
}
