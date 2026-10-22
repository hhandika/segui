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

  static ThemeData lightTheme() {
    return ThemeData(
      colorScheme: lightColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      drawerTheme: _drawerTheme,
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      colorScheme: darkColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      drawerTheme: _drawerTheme,
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

/// Chart colors. Series use the Okabe-Ito palette, which stays distinct
/// with color vision deficiency; quality zones reuse its green, orange, and
/// vermilion.
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

  /// Opacity of quality zones behind a chart.
  static const double zoneAlpha = 0.12;

  /// Opacity of the inner and outer quality ranges.
  static const double innerBandAlpha = 0.45;
  static const double outerBandAlpha = 0.2;

  static Color seriesAt(int index) => series[index % series.length];
}
