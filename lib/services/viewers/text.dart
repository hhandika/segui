import 'dart:io';
import 'package:flutter/foundation.dart';

class TextParser {
  Future<String> parse(File file) async {
    return compute(parseTextFile, file);
  }

  Future<String> parseTextFile(File file) async {
    return await file.readAsString();
  }
}
