import 'package:material_ui/material_ui.dart';

/// Material You design system recommend screen size
/// Desktop/Expanded screen: 840dp
/// Tablet/Medium screen: 600dp
/// Mobile/Compact screen: 360dp
/// Extra-large screen: 1600dp, such as a 1440p desktop monitor.
const double extraLargeScreenSize = 1600;
const double largeScreenSize = 1200;
const double expandedScreenSize = 840;
const double mediumScreenSize = 600;
const double compactScreenSize = 360;

/// Widest content area for pages that lay out cards in a grid, so wide
/// monitors fill with more columns instead of empty margins.
const double maxGridContentWidth = 2400;

/// Number of equal grid columns that fit [width] while keeping each item at
/// least [minItemWidth] wide, from one up to [maxColumns].
int gridColumnCount(
  double width, {
  required double minItemWidth,
  required int maxColumns,
  double spacing = 12,
}) {
  final int columns = ((width + spacing) / (minItemWidth + spacing)).floor();
  return columns.clamp(1, maxColumns);
}

/// Width of each item when [columns] share [width] with [spacing] between.
double gridItemWidth(double width, int columns, {double spacing = 12}) {
  return (width - spacing * (columns - 1)) / columns;
}

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

// Opaque so selected navigation labels keep WCAG AA contrast.
Color getIndicatorColor(BuildContext context) {
  return Theme.of(context).colorScheme.secondaryContainer;
}

// Opaque so icons keep WCAG AA non-text contrast.
Color getIconColor(BuildContext context) {
  return Theme.of(context).colorScheme.tertiary;
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
