import 'package:material_ui/material_ui.dart';

/// Material 3 window size class breakpoints, in logical pixels (dp).
/// https://m3.material.io/foundations/layout/applying-layout/window-size-classes
const double extraLargeScreenSize = 1600;
const double largeScreenSize = 1200;
const double expandedScreenSize = 840;
const double mediumScreenSize = 600;

/// Narrowest common phone width. Not a window size class breakpoint.
const double compactScreenSize = 360;

/// Material 3 window size classes, picked by the width of the app window.
///
/// - [compact]: under 600 dp, phones in portrait.
/// - [medium]: 600 to 839 dp, tablets in portrait and foldables.
/// - [expanded]: 840 to 1199 dp, tablets in landscape and small desktops.
/// - [large]: 1200 to 1599 dp, desktops.
/// - [extraLarge]: 1600 dp and wider, such as a 1440p desktop monitor.
enum WindowSizeClass {
  compact(0),
  medium(mediumScreenSize),
  expanded(expandedScreenSize),
  large(largeScreenSize),
  extraLarge(extraLargeScreenSize);

  const WindowSizeClass(this.minWidth);

  /// Narrowest window width in this class.
  final double minWidth;

  /// Size class of a window [width] wide.
  static WindowSizeClass fromWidth(double width) {
    return values.lastWhere((e) => width >= e.minWidth);
  }

  /// Size class of the window holding [context].
  static WindowSizeClass of(BuildContext context) {
    return fromWidth(MediaQuery.sizeOf(context).width);
  }

  /// Whether this class is [other] or wider.
  bool isAtLeast(WindowSizeClass other) => index >= other.index;
}

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

/// Shape of [getContainerDecoration] for a [Material], which clips its
/// child to the rounded corners and draws the outline on top.
RoundedRectangleBorder getContainerShape(BuildContext context) {
  return RoundedRectangleBorder(
    side: BorderSide(color: getBorderColor(context), width: 2),
    borderRadius: BorderRadius.circular(16),
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

/// Whether the window is [WindowSizeClass.compact].
bool isPhoneScreen(BuildContext context) {
  return WindowSizeClass.of(context) == WindowSizeClass.compact;
}

/// Whether the window is [WindowSizeClass.expanded] or wider, the large
/// screens of the Material guidelines.
/// https://material.io/blog/material-you-large-screens
bool isTabletScreen(BuildContext context) {
  return WindowSizeClass.of(context).isAtLeast(WindowSizeClass.expanded);
}

/// Whether the window is [WindowSizeClass.large] or wider.
bool isDesktopScreen(BuildContext context) {
  return WindowSizeClass.of(context).isAtLeast(WindowSizeClass.large);
}
