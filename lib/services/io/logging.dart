import 'dart:io';

import 'package:segui/services/io/io.dart';

class FileLoggingService {
  FileLoggingService();

  Future<List<File>> findLogs() async {
    final dir = await getSeguiDirectory();
    final files = dir.listSync().whereType<File>().toList();
    final results =
        files.where((element) => element.path.endsWith('.log')).toList();

    return _sortLogsByDate(results);
  }

  File? findLatestLog(List<File> files) {
    final logs =
        files.where((element) => element.path.endsWith('.log')).toList();
    final sortedLogs = _sortLogsByDate(logs);
    return sortedLogs.isNotEmpty ? sortedLogs.first : null;
  }

  List<File> _sortLogsByDate(List<File> logs) {
    logs.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return logs;
  }
}
