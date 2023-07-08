import 'package:flutter/material.dart';

class LearningResourcesPage extends StatefulWidget {
  const LearningResourcesPage({super.key});

  @override
  State<LearningResourcesPage> createState() => _LearningResourcesPageState();
}

class _LearningResourcesPageState extends State<LearningResourcesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Resources'),
        ),
        body: const Center(child: Text('Coming soon...')));
  }
}
