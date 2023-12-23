import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/screens/home/home.dart';
import 'package:segui/src/rust/api/handler.dart';
import 'package:segui/src/rust/frb_generated.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Directory appDocDir = await getApplicationDocumentsDirectory();
  await RustLib.init();
  initLogger(path: appDocDir.path);
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

// class SimpleTest extends StatefulWidget {
//   const SimpleTest({super.key});

//   @override
//   State<SimpleTest> createState() => _SimpleTestState();
// }

// class _SimpleTestState extends State<SimpleTest> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title: const Text('Simple Test'),
//         ),
//         body: Center(
//             child: Column(children: [
//           Text('Hello World: ${showDnaUppercase()}'),
//         ])));
//   }
// }
