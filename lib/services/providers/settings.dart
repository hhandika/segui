import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
