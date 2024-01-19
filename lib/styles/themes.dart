import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class SeguiTheme {
  static final _defaultLightColorScheme =
      FlexThemeData.light(scheme: FlexScheme.greenM3).colorScheme;

  static final _defaultDarkColorScheme =
      FlexThemeData.dark(scheme: FlexScheme.greenM3).colorScheme;

  static ThemeData lightTheme(ColorScheme? lightColorScheme) {
    return ThemeData(
      colorScheme: lightColorScheme ?? _defaultLightColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  static ThemeData darkTheme(ColorScheme? darkColorScheme) {
    return ThemeData(
      colorScheme: darkColorScheme ?? _defaultDarkColorScheme,
      useMaterial3: true,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
