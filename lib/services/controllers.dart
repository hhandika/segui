import 'package:flutter/material.dart';
import 'package:segui/services/types.dart';

class IOController {
  IOController({
    required this.prefixController,
    required this.outputDir,
    this.inputFormatController,
    required this.dataTypeController,
    this.outputFormatController,
    this.isRunning = false,
    this.isSuccess = false,
  });

  final TextEditingController prefixController;
  TextEditingController outputDir;
  String? inputFormatController;
  String dataTypeController;
  String? outputFormatController;
  bool isRunning;
  bool isSuccess;

  factory IOController.empty() => IOController(
        prefixController: TextEditingController(),
        outputDir: TextEditingController(),
        inputFormatController: inputFormat[0],
        dataTypeController: dataType[0],
      );

  bool get isValid {
    return !isRunning;
  }

  get isFileSelection => null;

  void reset() {
    prefixController.clear();
    outputDir.clear();
    inputFormatController = inputFormat[0];
    dataTypeController = dataType[0];
    outputFormatController = null;
    isRunning = false;
    isSuccess = false;
  }

  void dispose() {
    prefixController.dispose();
    outputDir.dispose();
  }
}
