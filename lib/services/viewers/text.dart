import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

class TextParser {
  Future<String> parse(XFile file) async {
    return compute(parseTextFile, file);
  }

  Future<String> parseTextFile(XFile file) async {
    return await file.readAsString();
  }
}
