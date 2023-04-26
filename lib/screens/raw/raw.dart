import 'package:flutter/material.dart';
import 'package:segui/screens/shared/forms.dart';

class RawPage extends StatefulWidget {
  const RawPage({super.key});

  @override
  State<RawPage> createState() => _RawPageState();
}

class _RawPageState extends State<RawPage> {
  @override
  Widget build(BuildContext context) {
    return const FormView(children: [
      CardTitle(title: 'Input'),
      SizedBox(height: 20),
      CardTitle(title: 'Output'),
    ]);
  }
}
