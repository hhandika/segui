import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/providers/settings.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/src/rust/api/common.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final logDir = await getApplicationDocumentsDirectory();
  await RustLib.init();
  await initLogger(logDir: logDir.path);
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
    return MaterialApp(
      title: 'SEGUL',
      debugShowCheckedModeBanner: false,
      theme: FlexThemeData.light(scheme: FlexScheme.green, useMaterial3: true),
      darkTheme:
          FlexThemeData.dark(scheme: FlexScheme.green, useMaterial3: true),
      themeMode: ref.watch(themeSettingProvider).when(
            data: (settings) => settings,
            loading: () => ThemeMode.system,
            error: (err, stack) => ThemeMode.system,
          ),
      home: const SegulHome(),
    );
  }
}
