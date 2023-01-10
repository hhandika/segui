import 'package:flutter/material.dart';
import 'package:segui/screens/home.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SEGUL',
      theme:
          FlexThemeData.light(scheme: FlexScheme.mandyRed, useMaterial3: true),
      darkTheme:
          FlexThemeData.dark(scheme: FlexScheme.mandyRed, useMaterial3: true),
      home: const SegulHome(title: 'HOME'),
    );
  }
}
