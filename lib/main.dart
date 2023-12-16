import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/screens/home/home.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:segui/services/native.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory appDocDir = await getApplicationDocumentsDirectory();
  segulApi.initLogger(path: appDocDir.path);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEGUL',
      theme: FlexThemeData.light(scheme: FlexScheme.green, useMaterial3: true),
      darkTheme:
          FlexThemeData.dark(scheme: FlexScheme.green, useMaterial3: true),
      home: const SegulHome(),
    );
  }
}
