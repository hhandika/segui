import 'package:material_ui/material_ui.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:segui/styles/decoration.dart';

/// SEGUI's "leaf and pollen" palette, taken from the app icon: the field
/// green of the icon background, an olive between that green and the
/// ribbon, and the ribbon's pollen gold. The warm gold keeps SEGUI distinct
/// from the cool teal used by NAHPU.
class SeguiTheme {
  static const Color leafGreen = Color(0xFF009245);
  static const Color olive = Color(0xFF5E7A3A);
  static const Color pollenGold = Color(0xFFFFD64F);

  /// Caps the primary chroma so the pale green containers stay calm instead
  /// of neon, while the secondary and tertiary keep their key colors.
  static const double _primaryChroma = 40;

  static final ColorScheme lightColorScheme = _colorScheme(Brightness.light);

  static final ColorScheme darkColorScheme = _colorScheme(Brightness.dark);

  /// [colors] are the chart, table, and residue colors from the SEGUL
  /// color library, chosen in settings.
  static ThemeData lightTheme({SeguiColors? colors}) {
    return ThemeData(
      colorScheme: lightColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      drawerTheme: _drawerTheme,
      extensions: [if (colors != null) colors],
    );
  }

  static ThemeData darkTheme({SeguiColors? colors}) {
    return ThemeData(
      colorScheme: darkColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      drawerTheme: _drawerTheme,
      extensions: [if (colors != null) colors],
    );
  }

  static const DrawerThemeData _drawerTheme = DrawerThemeData(
    width: navigationDrawerWidth,
  );

  static ColorScheme _colorScheme(Brightness brightness) {
    return SeedColorScheme.fromSeeds(
      brightness: brightness,
      primaryKey: leafGreen,
      secondaryKey: olive,
      tertiaryKey: pollenGold,
      tones: FlexTones.vivid(brightness).copyWith(
        primaryChroma: _primaryChroma,
      ),
    );
  }
}

/// Residue colors for the alignment viewer, keyed by upper-case ASCII code.
///
/// The app reads them from the SEGUL color library
/// (`segul_core::color::residue`) through [SeguiColors]. The
/// [ResiduePalette.nucleotide] and [ResiduePalette.aminoAcid] values mirror
/// its Clustal scheme for tests and the first frame, before Rust loads.
class ResiduePalette {
  const ResiduePalette({
    required this.colors,
    required this.fallback,
    required this.gap,
    required this.onResidue,
  });

  final Map<int, Color> colors;

  /// Residues missing from [colors], such as ambiguity codes.
  final Color fallback;

  /// Gaps and missing data.
  final Color gap;

  /// Residue letters drawn over the cell colors.
  final Color onResidue;

  Color colorOf(int code) {
    if (code == _gapCode || code == _missingCode) return gap;
    return colors[code] ?? fallback;
  }

  static const int _gapCode = 0x2D; // -
  static const int _missingCode = 0x3F; // ?

  /// Residue colors sent by the SEGUL color library.
  factory ResiduePalette.fromLibrary({
    required List<String> groupCodes,
    required List<int> groupColors,
    required int fallback,
    required int gap,
    required int onResidue,
  }) {
    return ResiduePalette(
      colors: {
        for (int i = 0; i < groupCodes.length; i++)
          for (final int code in groupCodes[i].codeUnits)
            code: Color(groupColors[i]),
      },
      fallback: Color(fallback),
      gap: Color(gap),
      onResidue: Color(onResidue),
    );
  }

  /// A green, C blue, G amber, and T or U red.
  factory ResiduePalette.nucleotide(Brightness brightness) {
    final bool light = brightness == Brightness.light;
    final Color red = light ? const Color(0xFFF09595) : const Color(0xFFA32D2D);
    return ResiduePalette(
      colors: {
        0x41: light ? const Color(0xFF97C459) : const Color(0xFF3B6D11),
        0x43: light ? const Color(0xFF85B7EB) : const Color(0xFF185FA5),
        0x47: light ? const Color(0xFFFAC775) : const Color(0xFF854F0B),
        0x54: red,
        0x55: red,
      },
      fallback: light ? const Color(0xFFB4B2A9) : const Color(0xFF5F5E5A),
      gap: light ? const Color(0xFFE6E4DC) : const Color(0xFF2C2C2A),
      onResidue: light ? const Color(0xFF2C2C2A) : const Color(0xFFF1EFE8),
    );
  }

  /// Amino acids grouped by chemistry, after the Clustal X scheme.
  factory ResiduePalette.aminoAcid(Brightness brightness) {
    final bool light = brightness == Brightness.light;
    final Color hydrophobic =
        light ? const Color(0xFF85B7EB) : const Color(0xFF185FA5);
    final Color positive =
        light ? const Color(0xFFF09595) : const Color(0xFFA32D2D);
    final Color negative =
        light ? const Color(0xFFED93B1) : const Color(0xFF993556);
    final Color polar =
        light ? const Color(0xFF97C459) : const Color(0xFF3B6D11);
    final Color aromatic =
        light ? const Color(0xFF5DCAA5) : const Color(0xFF0F6E56);
    final Color glycine =
        light ? const Color(0xFFFAC775) : const Color(0xFF854F0B);
    final Color proline =
        light ? const Color(0xFFFAEEDA) : const Color(0xFF633806);
    final Color cysteine =
        light ? const Color(0xFFF5C4B3) : const Color(0xFF993C1D);
    return ResiduePalette(
      colors: {
        for (final int c in 'AILMFWV'.codeUnits) c: hydrophobic,
        for (final int c in 'KR'.codeUnits) c: positive,
        for (final int c in 'DE'.codeUnits) c: negative,
        for (final int c in 'NQST'.codeUnits) c: polar,
        for (final int c in 'HY'.codeUnits) c: aromatic,
        0x47: glycine,
        0x50: proline,
        0x43: cysteine,
      },
      fallback: light ? const Color(0xFFB4B2A9) : const Color(0xFF5F5E5A),
      gap: light ? const Color(0xFFE6E4DC) : const Color(0xFF2C2C2A),
      onResidue: light ? const Color(0xFF2C2C2A) : const Color(0xFFF1EFE8),
    );
  }

  /// One residue color, for reading gaps and letters without base colors.
  factory ResiduePalette.mono(ColorScheme colors) {
    return ResiduePalette(
      colors: const {},
      fallback: colors.surfaceContainerHighest,
      gap: colors.surfaceContainerLow,
      onResidue: colors.onSurface,
    );
  }
}

/// Default chart colors and opacities. Series use the Okabe-Ito palette,
/// which stays distinct with color vision deficiency; quality zones reuse
/// its green, orange, and vermilion.
///
/// The colors mirror the SEGUL color library defaults for tests and the
/// first frame. Widgets read the colors chosen in settings from
/// [SeguiColors.of].
class ChartPalette {
  static const List<Color> series = [
    Color(0xFF0072B2),
    Color(0xFFE69F00),
    Color(0xFF009E73),
    Color(0xFFCC79A7),
    Color(0xFF56B4E9),
    Color(0xFFD55E00),
    Color(0xFFF0E442),
    Color(0xFF999999),
  ];

  static const Color pass = Color(0xFF009E73);
  static const Color warn = Color(0xFFE69F00);
  static const Color fail = Color(0xFFD55E00);

  /// The open sample on charts that summarize many samples, apart from
  /// the quality colors.
  static const Color open = Color(0xFFCC79A7);

  /// Samples far from the rest on a band chart.
  static const Color outlier = Color(0xFF999999);

  /// Opacity of quality zones behind a chart.
  static const double zoneAlpha = 0.12;

  /// Opacity of the inner and outer quality ranges.
  static const double innerBandAlpha = 0.45;
  static const double outerBandAlpha = 0.2;
}

/// Chart, table, and residue colors from the SEGUL color library
/// (`segul_core::color`), as chosen in settings. Every SEGUI chart, table,
/// and alignment viewer reads its colors here, so they match SEGUL plots.
///
/// Fills are the published palette colors. Lines, points, and outlines use
/// [lineFor], which is the fill darkened or lightened in SEGUL until it
/// reaches 3:1 against the surface (WCAG 2.2 SC 1.4.11).
@immutable
class SeguiColors extends ThemeExtension<SeguiColors> {
  const SeguiColors({
    required this.series,
    required this.seriesLines,
    required this.heatmap,
    required this.pass,
    required this.warn,
    required this.fail,
    required this.open,
    required this.outlier,
    required this.statusLines,
    required this.nucleotide,
    required this.aminoAcid,
    required this.nucleotideLines,
    this.tableBar,
  });

  /// Defaults matching SEGUL, for tests and the first frame.
  factory SeguiColors.fallback(Brightness brightness) {
    return SeguiColors(
      series: ChartPalette.series,
      seriesLines: ChartPalette.series,
      heatmap: const [],
      pass: ChartPalette.pass,
      warn: ChartPalette.warn,
      fail: ChartPalette.fail,
      open: ChartPalette.open,
      outlier: ChartPalette.outlier,
      statusLines: const {},
      nucleotide: ResiduePalette.nucleotide(brightness),
      aminoAcid: ResiduePalette.aminoAcid(brightness),
      // The other theme's cells are deep on light surfaces and pale on dark.
      nucleotideLines: ResiduePalette.nucleotide(
        brightness == Brightness.light ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// Series fills, in palette order.
  final List<Color> series;

  /// [series] adjusted to reach 3:1 against the surface.
  final List<Color> seriesLines;

  /// Evenly spaced heatmap colormap stops, low to high. Empty before the
  /// library loads, when heatmaps use the primary color.
  final List<Color> heatmap;

  final Color pass;
  final Color warn;
  final Color fail;
  final Color open;
  final Color outlier;

  /// Status colors adjusted to reach 3:1 against the surface.
  final Map<Color, Color> statusLines;

  final ResiduePalette nucleotide;
  final ResiduePalette aminoAcid;

  /// Nucleotide colors for lines on the surface, such as base composition
  /// along reads. They reach 3:1 against the surface.
  final ResiduePalette nucleotideLines;

  /// Table data bar color, or null for the theme's primary color.
  final Color? tableBar;

  /// The colors of the current theme, or the defaults when none are set.
  static SeguiColors of(BuildContext context) => fromTheme(Theme.of(context));

  static SeguiColors fromTheme(ThemeData theme) {
    return theme.extension<SeguiColors>() ??
        SeguiColors.fallback(theme.colorScheme.brightness);
  }

  Color seriesAt(int index) => series[index % series.length];

  Color lineAt(int index) => seriesLines[index % seriesLines.length];

  /// Line color for a series or status fill; other colors are returned as is.
  Color lineFor(Color fill) {
    final int i = series.indexOf(fill);
    if (i >= 0 && i < seriesLines.length) return seriesLines[i];
    return statusLines[fill] ?? fill;
  }

  ResiduePalette residues({required bool isDna}) =>
      isDna ? nucleotide : aminoAcid;

  Color dataBar(ColorScheme colors) => tableBar ?? colors.primary;

  /// Heatmap color at [t] in 0 to 1, or null before the library loads.
  Color? heatmapAt(double t) {
    if (heatmap.isEmpty) return null;
    final double clamped = t.isFinite ? t.clamp(0.0, 1.0) : 0.0;
    final double position = clamped * (heatmap.length - 1);
    final int low = position.floor();
    final int high = position.ceil();
    return Color.lerp(heatmap[low], heatmap[high], position - low);
  }

  @override
  SeguiColors copyWith({
    List<Color>? series,
    List<Color>? seriesLines,
    List<Color>? heatmap,
    Color? tableBar,
  }) {
    return SeguiColors(
      series: series ?? this.series,
      seriesLines: seriesLines ?? this.seriesLines,
      heatmap: heatmap ?? this.heatmap,
      pass: pass,
      warn: warn,
      fail: fail,
      open: open,
      outlier: outlier,
      statusLines: statusLines,
      nucleotide: nucleotide,
      aminoAcid: aminoAcid,
      nucleotideLines: nucleotideLines,
      tableBar: tableBar ?? this.tableBar,
    );
  }

  /// Palettes are discrete, so a theme change swaps them halfway.
  @override
  SeguiColors lerp(SeguiColors? other, double t) {
    if (other == null) return this;
    return t < 0.5 ? this : other;
  }
}
