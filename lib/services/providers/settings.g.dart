// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$settingHash() => r'8d3ecafee3305b91918d38dce44046849a6590d1';

/// See also [setting].
@ProviderFor(setting)
final settingProvider = Provider<SharedPreferences>.internal(
  setting,
  name: r'settingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$settingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SettingRef = ProviderRef<SharedPreferences>;
String _$themeSettingHash() => r'5493e98fe97e213af398d1f7acaadf065b90d6ca';

/// See also [ThemeSetting].
@ProviderFor(ThemeSetting)
final themeSettingProvider =
    AsyncNotifierProvider<ThemeSetting, ThemeMode>.internal(
  ThemeSetting.new,
  name: r'themeSettingProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$themeSettingHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$ThemeSetting = AsyncNotifier<ThemeMode>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
