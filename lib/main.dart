import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/src/rust/api/common.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:segui/styles/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final logDir = await getSeguiDirectory();
  await RustLib.init();
  try {
    await initLogger(logDir: logDir.path);
  } catch (e) {
    if (kDebugMode) {
      print('Failed to initialize logger. It may have been initiated');
    }
  }
  runApp(ProviderScope(
    overrides: [
      settingProvider.overrideWithValue(prefs),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(builder: (lightColorScheme, darkColorScheme) {
      return MaterialApp(
        title: 'SEGUL',
        debugShowCheckedModeBanner: false,
        theme: SeguiTheme.lightTheme(lightColorScheme),
        darkTheme: SeguiTheme.darkTheme(darkColorScheme),
        themeMode: ref.watch(themeSettingProvider).when(
              data: (settings) => settings,
              loading: () => ThemeMode.system,
              error: (err, stack) => ThemeMode.system,
            ),
        home: const SegulHome(),
      );
    });
  }
}
