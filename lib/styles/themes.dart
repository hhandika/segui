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
