import 'package:flutter/material.dart';
import 'package:segui/services/utils.dart';

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

Color? getSEGULBackgroundColor(BuildContext context) {
  return Color.lerp(Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.surface, 0.9);
}

Color getBorderColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withAlpha(40);
}

bool isMediumScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= 600;
}

// Large screen is defined as screen width >= 840 dp
// Based on Material Design guidelines for expanded screen.
// https://material.io/blog/material-you-large-screens
bool isExpandedScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= mediumScreenSize;
}

bool isDesktopScreen(BuildContext context) {
  return MediaQuery.of(context).size.width >= largeScreenSize;
}
