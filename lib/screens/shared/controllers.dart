import 'dart:io';

import 'package:flutter/material.dart';
import 'package:segui/services/types.dart';

class IOController {
  IOController({
    required this.outputController,
    required this.dirPath,
    required this.outputDir,
    required this.files,
    this.inputFormatController,
    required this.dataTypeController,
    this.outputFormatController,
    this.isRunning = false,
    this.isSuccess = false,
  });

  final TextEditingController outputController;
  List<String> files;
  TextEditingController dirPath;
  TextEditingController outputDir;
  String? inputFormatController;
  String dataTypeController;
  String? outputFormatController;
  bool isRunning;
  bool isSuccess;

  factory IOController.empty() => IOController(
        outputController: TextEditingController(),
        dirPath: TextEditingController(),
        outputDir: TextEditingController(),
        files: [],
        inputFormatController: inputFormat[0],
        dataTypeController: dataType[0],
      );

  bool isValid() {
    bool validInputPath = files.isNotEmpty;
    bool validOutputPath = Platform.isIOS || outputDir.text.isNotEmpty;
    return validInputPath && validOutputPath && inputFormatController != null;
  }

  void reset() {
    outputController.clear();
    dirPath.clear();
    outputDir.clear();
    files.clear();
    inputFormatController = inputFormat[0];
    dataTypeController = dataType[0];
    outputFormatController = null;
    isRunning = false;
    isSuccess = false;
  }

  void dispose() {
    outputController.dispose();
    dirPath.dispose();
  }
}
