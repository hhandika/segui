import 'package:flutter/material.dart';
import 'package:segui/screens/shared/forms.dart';

class ContigPage extends StatefulWidget {
  const ContigPage({super.key});

  @override
  State<ContigPage> createState() => _ContigPageState();
}

class _ContigPageState extends State<ContigPage> {
  @override
  Widget build(BuildContext context) {
    return const FormView(children: [
      CardTitle(title: 'Input'),
      SizedBox(height: 20),
      CardTitle(title: 'Output'),
    ]);
  }
}
