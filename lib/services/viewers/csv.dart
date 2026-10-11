import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';

class CsvParser {
  CsvParser();

  Future<List<List<dynamic>>> parse(File file) async {
    return await _parse(file);
  }

  Future<List<List<dynamic>>> _parse(File file) async {
    final handler = file.openRead();
    // The decoder detects line endings; keep number parsing from csv 6.
    final lines = await handler
        .transform(utf8.decoder)
        .transform(const CsvDecoder(fieldDelimiter: ',', dynamicTyping: true))
        .toList();

    return lines;
  }
}
