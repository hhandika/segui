import 'package:flutter/material.dart';
import 'package:segui/services/types.dart';

class IOController {
  IOController({
    required this.outputController,
    required this.outputDir,
    this.inputFormatController,
    required this.dataTypeController,
    this.outputFormatController,
    this.isRunning = false,
    this.isSuccess = false,
    this.isShowingInfo = true,
  });

  final TextEditingController outputController;
  TextEditingController outputDir;
  String? inputFormatController;
  String dataTypeController;
  String? outputFormatController;
  bool isRunning;
  bool isSuccess;
  bool isShowingInfo = true;

  factory IOController.empty() => IOController(
        outputController: TextEditingController(),
        outputDir: TextEditingController(),
        inputFormatController: inputFormat[0],
        dataTypeController: dataType[0],
      );

  bool get isValid {
    return !isRunning;
  }

  void reset() {
    outputController.clear();
    outputDir.clear();
    inputFormatController = inputFormat[0];
    dataTypeController = dataType[0];
    outputFormatController = null;
    isRunning = false;
    isSuccess = false;
  }

  void dispose() {
    outputController.dispose();
    outputDir.dispose();
  }
}
