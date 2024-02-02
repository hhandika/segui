import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:file_selector/file_selector.dart';

class CsvParser {
  CsvParser();

  Future<List<List<dynamic>>> parse(XFile file) {
    return _parse(file);
  }

  Future<List<List<dynamic>>> _parse(XFile file) async {
    final handler = File(file.path).openRead();
    const eolDetector = FirstOccurrenceSettingsDetector(
      eols: ['\r\n', '\n'],
    );
    final lines = await handler
        .transform(utf8.decoder)
        .transform(const CsvToListConverter(csvSettingsDetector: eolDetector))
        .toList();

    return lines;
  }
}
