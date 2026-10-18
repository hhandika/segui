/// Canonical visual values for SEGUI.
///
/// Keep values on the curated even-number scale shared with NAHPU. Ratios,
/// animation durations, responsive calculations, and window size class
/// breakpoints (see `decoration.dart`) are not design tokens.
abstract final class SeguiSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double display = 48;
  static const double displayLarge = 64;
}

abstract final class SeguiRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  /// Fully rounded ends, such as pills and search bars.
  static const double full = 999;
}

abstract final class SeguiStroke {
  static const double none = 0;
  static const double thin = 1;
  static const double regular = 2;
  static const double thick = 4;
}

abstract final class SeguiElevation {
  static const double none = 0;
  static const double low = 2;
  static const double medium = 4;
  static const double high = 8;
  static const double overlay = 12;
}

abstract final class SeguiControlSize {
  static const double indicator = 8;
  static const double iconSmall = 16;
  static const double iconMedium = 20;
  static const double icon = 24;
  static const double badge = 28;
  static const double iconLarge = 32;
  static const double avatar = 36;
  static const double control = 40;
  static const double touchTarget = 48;

  /// Height of the primary run button on tool pages.
  static const double primaryAction = 52;
  static const double prominent = 64;
  static const double illustrationSmall = 72;
  static const double illustration = 80;
  static const double illustrationLarge = 96;

  /// Height of the feature diagram preview on quick start guide cards.
  static const double diagramPreview = 140;

  /// Width of the gull scene preview on a compact theme choice.
  static const double themePreview = 120;

  /// Height of the mascot art on the about sheet.
  static const double aboutArt = 128;

  /// Tallest tool search suggestions view on larger screens.
  static const double searchViewMax = 520;

  /// Lane beside scrolling content that holds its scrollbar, as wide as
  /// a hovered Material scrollbar, so the thumb never covers content.
  static const double scrollbarGutter = SeguiSpacing.lg;
}

/// Spacing inside tool forms. Fields in a [FormCard] sit [fieldGap] apart,
/// while a helper text sits [helperGap] below the field it explains, so each
/// helper reads as part of its field rather than of the next one.
abstract final class SeguiFormLayout {
  static const double fieldGap = SeguiSpacing.xl;
  static const double helperGap = SeguiSpacing.xs;
  static const double cardPadding = SeguiSpacing.xl;
  static const double cardRadius = SeguiRadius.lg;
  static const double fieldRadius = SeguiRadius.md;
  static const double sectionTitleTop = SeguiSpacing.xxl;
  static const double sectionTitleBottom = SeguiSpacing.md;
}

/// Gap between a scrolling page and the window edge.
abstract final class SeguiPageMargin {
  static const double compact = SeguiSpacing.lg;
  static const double regular = SeguiSpacing.xxl;
}

abstract final class SeguiContentWidth {
  /// Side panels and pickers beside a page.
  static const double panel = 320;
  static const double card = 380;

  /// Confirmations and other short dialogs.
  static const double dialog = 480;
  static const double form = 600;
  static const double reading = 800;
  static const double wide = 900;

  /// Quick start pages with multi-column guide grids.
  static const double guide = 1100;

  /// Statistic tiles, such as the file count on the data usage page.
  static const double statTile = 200;

  /// Narrowest workbench file summary tile before input and output stack.
  static const double summaryTile = 140;

  /// Narrowest theme choice card before the choices stack as rows.
  static const double themeChoice = 200;

  /// App bar tool search field.
  static const double searchBar = 280;

  /// Narrowest tool search suggestions view on larger screens.
  static const double searchViewMin = 360;
}

/// Sizes in the alignment viewer.
abstract final class SeguiAlignmentLayout {
  /// Narrowest and widest residue cell, and the starting width.
  static const double cellMin = 2;
  static const double cellMax = 24;
  static const double cellDefault = 14;

  /// Zoom step for the zoom buttons and Ctrl (or Cmd) + scroll.
  static const double cellStep = 2;

  /// Narrowest cell that still shows residue letters.
  static const double letterMin = 10;

  /// Narrowest cell drawn with a gap between neighbors.
  static const double cellGapMin = 6;

  /// Rows stay tall enough for taxon names when cells are narrow.
  static const double rowMin = 14;

  /// Room below the last sequence, so it clears the panel border.
  static const double gridBottomPadding = SeguiSpacing.sm;

  static const double ruler = 24;

  /// Shortest the grid panel gets; shorter windows scroll the viewer.
  static const double gridMin = 320;

  /// Height of the gull at work above the toolbar.
  static const double mascot = 48;
  static const double overview = 48;
  static const double nameColumn = 160;
  static const double nameColumnCompact = 96;

  /// Range the name panel can be dragged to.
  static const double nameColumnMin = 64;
  static const double nameColumnMax = 400;

  /// Grab area of the divider between the names and the grid.
  static const double nameDivider = 8;
  static const double chunkSidebar = 200;

  /// List of files to switch between, beside the viewer.
  static const double fileList = 240;

  /// Widest the go-to-site field grows to fit its label and hint.
  static const double siteFieldMax = 200;

  /// Narrowest the file switcher gets beside the gull; narrower rows hide
  /// the gull.
  static const double fileSwitcherMin = 320;
}
