import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';

class CsvParser {
  CsvParser();

  Future<List<List<dynamic>>> parse(File file) async {
    return await _parse(file);
  }

  Future<List<List<dynamic>>> _parse(File file) async {
    final handler = file.openRead();
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
