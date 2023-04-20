import 'package:flutter/material.dart';

class IOController {
  IOController({
    required this.outputController,
    this.dirPath,
    this.outputDir,
    this.inputFormatController,
    this.dataTypeController,
    this.outputFormatController,
  });

  final TextEditingController outputController;
  String? dirPath;
  String? outputDir;
  String? inputFormatController;
  String? dataTypeController;
  String? outputFormatController;

  factory IOController.empty() => IOController(
        outputController: TextEditingController(),
      );

  void reset() {
    dirPath = null;
    outputDir = null;
    outputController.text = '';
  }

  void dispose() {
    outputController.dispose();
  }
}
