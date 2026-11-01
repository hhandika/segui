import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:segui/src/rust/api/colors.dart' as lib;
import 'package:segui/styles/design_tokens.dart';
import 'package:segui/styles/themes.dart';

/// Default SEGUL color names, used before settings are saved.
const String defaultChartPalette = 'dark2';
const String defaultHeatmapColormap = 'viridis';
const String defaultResidueScheme = 'clustal';

/// WCAG 2.2 SC 1.4.11 contrast for lines and marks.
const double nonTextContrast = 3.0;

/// WCAG 2.2 SC 1.4.3 contrast for normal text.
const double textContrast = 4.5;

/// Colormap stops sent to the app. Heatmaps interpolate between them.
const int heatmapStops = 64;

/// Where table data bars take their color from.
enum TableBarColor {
  themePrimary('Theme color'),
  palette('Chart palette');

  const TableBarColor(this.label);

  final String label;
}

/// The color choices saved in settings.
@immutable
class ColorPreferences {
  const ColorPreferences({
    this.palette = defaultChartPalette,
    this.colormap = defaultHeatmapColormap,
    this.residueScheme = defaultResidueScheme,
    this.tableBar = TableBarColor.themePrimary,
  });

  final String palette;
  final String colormap;
  final String residueScheme;
  final TableBarColor tableBar;

  @override
  bool operator ==(Object other) =>
      other is ColorPreferences &&
      other.palette == palette &&
      other.colormap == colormap &&
      other.residueScheme == residueScheme &&
      other.tableBar == tableBar;

  @override
  int get hashCode => Object.hash(palette, colormap, residueScheme, tableBar);
}

/// Reads chart, table, and residue colors from the SEGUL color library.
class ColorLibraryServices {
  const ColorLibraryServices();

  /// Colors for [settings] on a [surface] of the given [brightness].
  /// Falls back to the defaults when the library is not loaded, as in
  /// widget tests, or a saved name is no longer known.
  SeguiColors load({
    required ColorPreferences settings,
    required Brightness brightness,
    required Color surface,
  }) {
    try {
      return _load(settings, brightness, surface);
    } catch (e) {
      if (kDebugMode) print('Failed loading SEGUL colors: $e');
      return SeguiColors.fallback(brightness);
    }
  }

  List<lib.PaletteOption> paletteOptions() => lib.paletteOptions();

  List<lib.ColormapOption> colormapOptions() => lib.colormapOptions();

  List<lib.ColorOption> residueSchemeOptions() => lib.residueSchemeOptions();

  List<lib.ColorOption> cvdOptions() => lib.cvdOptions();

  /// The first [n] colors of [palette], with line colors for [surface].
  lib.PaletteColors paletteColors(String palette, int n, Color surface) {
    return lib.paletteColors(
      name: palette,
      n: n,
      background: surface.toARGB32(),
    );
  }

  List<Color> colormapStops(String colormap, int n) => [
        for (final int c in lib.colormapStops(name: colormap, n: n)) Color(c),
      ];

  /// [color] as seen with a color vision deficiency, keeping its opacity.
  Color simulate(Color color, String cvd) {
    final int rgb = lib.simulateCvd(color: color.toARGB32(), kind: cvd);
    return Color(rgb).withValues(alpha: color.a);
  }

  double contrastRatio(Color a, Color b) =>
      lib.contrastRatio(a: a.toARGB32(), b: b.toARGB32());

  /// Every choice, with colors for a [surface] of the given [brightness].
  ColorChoices choices({
    required Brightness brightness,
    required Color surface,
  }) {
    try {
      final bool dark = brightness == Brightness.dark;
      ResiduePalette residues(String scheme, bool isDna) {
        final lib.ResidueColors c = lib.residueColors(
          scheme: scheme,
          dark: dark,
          isDna: isDna,
        );
        return ResiduePalette.fromLibrary(
          groupCodes: c.groupCodes,
          groupColors: c.groupColors,
          fallback: c.fallback,
          gap: c.gap,
          onResidue: c.onResidue,
        );
      }

      return ColorChoices(
        palettes: [
          for (final lib.PaletteOption p in paletteOptions())
            _paletteChoice(p, surface),
        ],
        colormaps: [
          for (final lib.ColormapOption c in colormapOptions())
            ColormapChoice(
              name: c.name,
              label: c.label,
              isDiverging: c.diverging,
              stops: colormapStops(c.name, heatmapStops),
            ),
        ],
        residueSchemes: [
          for (final lib.ColorOption s in residueSchemeOptions())
            ResidueChoice(
              name: s.name,
              label: s.label,
              nucleotide: residues(s.name, true),
              aminoAcid: residues(s.name, false),
            ),
        ],
        cvdKinds: [
          for (final lib.ColorOption k in cvdOptions()) (k.name, k.label),
        ],
      );
    } catch (e) {
      if (kDebugMode) print('Failed loading SEGUL color choices: $e');
      return ColorChoices.fallback(brightness);
    }
  }

  /// [colors] as seen with the color vision deficiency [cvd].
  SeguiColors simulateAll(SeguiColors colors, String cvd) {
    Color sim(Color c) => simulate(c, cvd);
    ResiduePalette simResidues(ResiduePalette p) => ResiduePalette(
          colors: p.colors.map((code, c) => MapEntry(code, sim(c))),
          fallback: sim(p.fallback),
          gap: sim(p.gap),
          onResidue: sim(p.onResidue),
        );
    return SeguiColors(
      series: [for (final Color c in colors.series) sim(c)],
      seriesLines: [for (final Color c in colors.seriesLines) sim(c)],
      heatmap: [for (final Color c in colors.heatmap) sim(c)],
      pass: sim(colors.pass),
      warn: sim(colors.warn),
      fail: sim(colors.fail),
      open: sim(colors.open),
      outlier: sim(colors.outlier),
      statusLines: colors.statusLines.map(
        (fill, line) => MapEntry(sim(fill), sim(line)),
      ),
      nucleotide: simResidues(colors.nucleotide),
      aminoAcid: simResidues(colors.aminoAcid),
      nucleotideLines: simResidues(colors.nucleotideLines),
      tableBar: colors.tableBar == null ? null : sim(colors.tableBar!),
    );
  }

  /// The weakest text and line contrast in [colors] on [scheme]'s surface.
  ContrastSummary summarize(SeguiColors colors, ColorScheme scheme) {
    final Color surface = scheme.surface;
    final Color bar = Color.alphaBlend(
      colors.dataBar(scheme).withValues(alpha: SeguiTableLayout.dataBarAlpha),
      surface,
    );
    final List<double> text = [
      contrastRatio(scheme.onSurface, bar),
      for (final ResiduePalette p in [colors.nucleotide, colors.aminoAcid])
        for (final Color cell in {...p.colors.values, p.fallback, p.gap})
          contrastRatio(p.onResidue, cell),
    ];
    final List<double> lines = [
      for (final Color line in colors.seriesLines) contrastRatio(line, surface),
    ];
    return ContrastSummary(
      text: text.reduce((a, b) => a < b ? a : b),
      lines: lines.reduce((a, b) => a < b ? a : b),
    );
  }

  SeguiColors _load(
    ColorPreferences settings,
    Brightness brightness,
    Color surface,
  ) {
    final int background = surface.toARGB32();
    final lib.PaletteOption palette = paletteOptions().firstWhere(
      (p) => p.name == settings.palette,
      orElse: () => paletteOptions().first,
    );
    final lib.PaletteColors series = paletteColors(
      palette.name,
      palette.size,
      surface,
    );
    final lib.StatusColorsData status =
        lib.statusColors(background: background);
    final bool dark = brightness == Brightness.dark;
    ResiduePalette residues(bool isDna, {bool asLines = false}) {
      // Lines take the other theme's cells, deep on light surfaces and
      // pale on dark ones, adjusted to reach 3:1.
      final lib.ResidueColors c = lib.residueColors(
        scheme: settings.residueScheme,
        dark: asLines ? !dark : dark,
        isDna: isDna,
      );
      return ResiduePalette.fromLibrary(
        groupCodes: c.groupCodes,
        groupColors: asLines
            ? [
                for (final int color in c.groupColors)
                  lib.ensureContrast(
                    color: color,
                    background: background,
                    min: nonTextContrast,
                  ),
              ]
            : c.groupColors,
        fallback: c.fallback,
        gap: c.gap,
        onResidue: c.onResidue,
      );
    }

    final List<Color> fills = [for (final int c in series.fill) Color(c)];
    return SeguiColors(
      series: fills,
      seriesLines: [for (final int c in series.line) Color(c)],
      heatmap: colormapStops(settings.colormap, heatmapStops),
      pass: Color(status.pass),
      warn: Color(status.warn),
      fail: Color(status.fail),
      open: Color(status.open),
      outlier: Color(status.outlier),
      statusLines: {
        Color(status.pass): Color(status.passLine),
        Color(status.warn): Color(status.warnLine),
        Color(status.fail): Color(status.failLine),
        Color(status.open): Color(status.openLine),
        Color(status.outlier): Color(status.outlierLine),
      },
      nucleotide: residues(true),
      aminoAcid: residues(false),
      nucleotideLines: residues(true, asLines: true),
      tableBar: settings.tableBar == TableBarColor.palette ? fills.first : null,
    );
  }

  PaletteChoice _paletteChoice(lib.PaletteOption option, Color surface) {
    final lib.PaletteColors colors =
        paletteColors(option.name, option.size, surface);
    return PaletteChoice(
      name: option.name,
      label: option.label,
      colorblindSafe: option.colorblindSafe,
      fills: [for (final int c in colors.fill) Color(c)],
      lines: [for (final int c in colors.line) Color(c)],
    );
  }
}

/// A chart palette with its colors on the current surface.
@immutable
class PaletteChoice {
  const PaletteChoice({
    required this.name,
    required this.label,
    required this.colorblindSafe,
    required this.fills,
    required this.lines,
  });

  final String name;
  final String label;

  /// Colors, from the start, that stay distinct with color vision
  /// deficiencies.
  final int colorblindSafe;
  final List<Color> fills;
  final List<Color> lines;

  bool get isColorblindSafe => colorblindSafe >= fills.length;
}

/// A heatmap colormap with its stops.
@immutable
class ColormapChoice {
  const ColormapChoice({
    required this.name,
    required this.label,
    required this.isDiverging,
    required this.stops,
  });

  final String name;
  final String label;
  final bool isDiverging;
  final List<Color> stops;
}

/// A residue color scheme in the current theme.
@immutable
class ResidueChoice {
  const ResidueChoice({
    required this.name,
    required this.label,
    required this.nucleotide,
    required this.aminoAcid,
  });

  final String name;
  final String label;
  final ResiduePalette nucleotide;
  final ResiduePalette aminoAcid;
}

/// Every color choice the settings offer, with the colors to preview them.
@immutable
class ColorChoices {
  const ColorChoices({
    required this.palettes,
    required this.colormaps,
    required this.residueSchemes,
    required this.cvdKinds,
  });

  /// Only the defaults, when the library is not loaded.
  factory ColorChoices.fallback(Brightness brightness) {
    return ColorChoices(
      palettes: const [
        PaletteChoice(
          name: defaultChartPalette,
          label: 'ColorBrewer Dark2',
          colorblindSafe: 3,
          fills: ChartPalette.series,
          lines: ChartPalette.series,
        ),
      ],
      colormaps: const [],
      residueSchemes: [
        ResidueChoice(
          name: defaultResidueScheme,
          label: 'Clustal',
          nucleotide: ResiduePalette.nucleotide(brightness),
          aminoAcid: ResiduePalette.aminoAcid(brightness),
        ),
      ],
      cvdKinds: const [],
    );
  }

  final List<PaletteChoice> palettes;
  final List<ColormapChoice> colormaps;
  final List<ResidueChoice> residueSchemes;

  /// Color vision deficiencies to preview, as (name, label).
  final List<(String, String)> cvdKinds;
}

/// The weakest contrast among the colors a preview draws.
@immutable
class ContrastSummary {
  const ContrastSummary({required this.text, required this.lines});

  /// Weakest text: residue letters and numbers over table bars.
  final double text;

  /// Weakest series line against the surface.
  final double lines;
}
