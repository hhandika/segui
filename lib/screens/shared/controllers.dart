import 'package:flutter/material.dart';
import 'package:segui/screens/shared/types.dart';

class IOController {
  IOController({
    required this.outputController,
    this.dirPath,
    this.outputDir,
    required this.files,
    this.inputFormatController,
    required this.dataTypeController,
    this.outputFormatController,
  });

  final TextEditingController outputController;
  List<String?> files;
  String? dirPath;
  String? outputDir;
  String? inputFormatController;
  String dataTypeController;
  String? outputFormatController;

  factory IOController.empty() => IOController(
        outputController: TextEditingController(),
        files: [],
        dataTypeController: dataType[0],
      );

  bool isValid() {
    return dirPath != null ||
        files.isNotEmpty &&
            outputDir != null &&
            inputFormatController != null &&
            outputFormatController != null;
  }

  void reset() {
    dirPath = null;
    outputDir = null;
    outputController.text = '';
  }

  void dispose() {
    outputController.dispose();
  }
}
