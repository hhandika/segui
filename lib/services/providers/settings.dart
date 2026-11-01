import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/colors.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Overridden in `ProviderScope` with the loaded preferences.
final settingProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError(),
);

final themeSettingProvider =
    AsyncNotifierProvider<ThemeSetting, ThemeMode>(ThemeSetting.new);

class ThemeSetting extends AsyncNotifier<ThemeMode> {
  Future<ThemeMode> _fetchSetting() async {
    final prefs = ref.watch(settingProvider);
    final savedTheme = prefs.getString('themeMode');

    // Set to default system theme if no setting is found
    final ThemeMode currentTheme = _matchThemeMode(savedTheme);
    if (savedTheme == null) {
      await prefs.setString('themeMode', _matchThemeModeToString(currentTheme));
    }

    return currentTheme;
  }

  @override
  FutureOr<ThemeMode> build() async {
    return await _fetchSetting();
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final prefs = ref.watch(settingProvider);
      final themeMode = _matchThemeModeToString(mode);
      await prefs.setString('themeMode', themeMode);
      return mode;
    });
  }

  ThemeMode _matchThemeMode(String? savedTheme) {
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'dark':
          return ThemeMode.dark;
        case 'light':
          return ThemeMode.light;
        case 'system':
          return ThemeMode.system;
      }
    }
    return ThemeMode.system;
  }

  String _matchThemeModeToString(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }
}

/// Home screen layouts the user can switch between.
enum HomeView { tools, workflows }

final homeViewProvider =
    NotifierProvider<HomeViewSetting, HomeView>(HomeViewSetting.new);

/// Remembers whether the home screen shows all tools or common workflows.
class HomeViewSetting extends Notifier<HomeView> {
  static const String _key = 'homeView';

  @override
  HomeView build() {
    final String? saved = ref.watch(settingProvider).getString(_key);
    return HomeView.values.firstWhere(
      (view) => view.name == saved,
      orElse: () => HomeView.tools,
    );
  }

  Future<void> setView(HomeView view) async {
    state = view;
    await ref.read(settingProvider).setString(_key, view.name);
  }
}

final reduceMotionProvider =
    NotifierProvider<ReduceMotionSetting, bool>(ReduceMotionSetting.new);

/// Remembers whether the app stops decorative animations, such as the gull
/// at work. The device's reduce motion setting applies either way.
class ReduceMotionSetting extends Notifier<bool> {
  static const String _key = 'reduceMotion';

  @override
  bool build() => ref.watch(settingProvider).getBool(_key) ?? false;

  Future<void> setReduceMotion(bool value) async {
    state = value;
    await ref.read(settingProvider).setBool(_key, value);
  }
}

final chartPaletteProvider = NotifierProvider<ColorNameSetting, String>(
  () => ColorNameSetting('chartPalette', defaultChartPalette),
);

final heatmapColormapProvider = NotifierProvider<ColorNameSetting, String>(
  () => ColorNameSetting('heatmapColormap', defaultHeatmapColormap),
);

final residueSchemeProvider = NotifierProvider<ColorNameSetting, String>(
  () => ColorNameSetting('residueScheme', defaultResidueScheme),
);

/// Remembers a SEGUL color name, such as a palette or colormap.
class ColorNameSetting extends Notifier<String> {
  ColorNameSetting(this._key, this._default);

  final String _key;
  final String _default;

  @override
  String build() => ref.watch(settingProvider).getString(_key) ?? _default;

  Future<void> set(String name) async {
    state = name;
    await ref.read(settingProvider).setString(_key, name);
  }
}

final tableBarColorProvider =
    NotifierProvider<TableBarColorSetting, TableBarColor>(
  TableBarColorSetting.new,
);

/// Remembers where table data bars take their color from.
class TableBarColorSetting extends Notifier<TableBarColor> {
  static const String _key = 'tableBarColor';

  @override
  TableBarColor build() {
    final String? saved = ref.watch(settingProvider).getString(_key);
    return TableBarColor.values.firstWhere(
      (c) => c.name == saved,
      orElse: () => TableBarColor.themePrimary,
    );
  }

  Future<void> set(TableBarColor color) async {
    state = color;
    await ref.read(settingProvider).setString(_key, color.name);
  }
}

final alignmentColorModeProvider =
    NotifierProvider<AlignmentColorModeSetting, AlignmentColorMode>(
  AlignmentColorModeSetting.new,
);

/// Remembers how the alignment viewer colors residues.
class AlignmentColorModeSetting extends Notifier<AlignmentColorMode> {
  static const String _key = 'alignmentColorMode';

  @override
  AlignmentColorMode build() {
    final String? saved = ref.watch(settingProvider).getString(_key);
    return AlignmentColorMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => AlignmentColorMode.base,
    );
  }

  Future<void> set(AlignmentColorMode mode) async {
    state = mode;
    await ref.read(settingProvider).setString(_key, mode.name);
  }
}

final colorSettingsProvider = Provider<ColorPreferences>(
  (ref) => ColorPreferences(
    palette: ref.watch(chartPaletteProvider),
    colormap: ref.watch(heatmapColormapProvider),
    residueScheme: ref.watch(residueSchemeProvider),
    tableBar: ref.watch(tableBarColorProvider),
  ),
);

final colorLibraryProvider = Provider<ColorLibraryServices>(
  (ref) => const ColorLibraryServices(),
);

/// Chart, table, and residue colors for a theme brightness, from the SEGUL
/// color library and the saved color settings.
final seguiColorsProvider = Provider.family<SeguiColors, Brightness>(
  (ref, brightness) {
    final ColorScheme scheme = brightness == Brightness.light
        ? SeguiTheme.lightColorScheme
        : SeguiTheme.darkColorScheme;
    return ref.watch(colorLibraryProvider).load(
          settings: ref.watch(colorSettingsProvider),
          brightness: brightness,
          surface: scheme.surface,
        );
  },
);

/// Color choices with preview colors for a theme brightness.
final colorChoicesProvider = Provider.family<ColorChoices, Brightness>(
  (ref, brightness) {
    final ColorScheme scheme = brightness == Brightness.light
        ? SeguiTheme.lightColorScheme
        : SeguiTheme.darkColorScheme;
    return ref.watch(colorLibraryProvider).choices(
          brightness: brightness,
          surface: scheme.surface,
        );
  },
);
