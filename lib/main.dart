import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/settings.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/screens/shared/motion.dart';
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
    return MaterialApp(
      title: 'SEGUL',
      debugShowCheckedModeBanner: false,
      theme: SeguiTheme.lightTheme(),
      darkTheme: SeguiTheme.darkTheme(),
      themeMode: ref.watch(themeSettingProvider).when(
            data: (settings) => settings,
            loading: () => ThemeMode.system,
            error: (err, stack) => ThemeMode.system,
          ),
      builder: (context, child) =>
          ReduceMotionScope(child: child ?? const SizedBox.shrink()),
      home: const SegulHome(),
    );
  }
}
