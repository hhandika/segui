import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_selector/file_selector.dart';

class CsvParser {
  CsvParser({required this.file});

  final XFile file;

  Future<List<List<String>>> parse() async {
    final handler = File(file.path).openRead();

    final lines = await handler
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    return parseAsString(lines);
  }

  List<List<String>> parseAsString(List<List<dynamic>> lines) {
    return lines.map((e) => e.map((e) => e.toString()).toList()).toList();
  }
}
