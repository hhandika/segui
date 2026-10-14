import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

/// File count, total size, and count per format for a set of files.
class FileSetSummary {
  const FileSetSummary({
    required this.fileCount,
    required this.totalBytes,
    required this.formatCounts,
  });

  const FileSetSummary.empty()
      : fileCount = 0,
        totalBytes = 0,
        formatCounts = const [];

  final int fileCount;
  final int totalBytes;

  /// Formats with their file counts, most common first.
  final List<({FileIconType format, int count})> formatCounts;

  bool get isEmpty => fileCount == 0;

  String get totalSize => FileUtils().formatSize(totalBytes);

  /// Summarizes [files], counting files that no longer exist as zero bytes.
  static Future<FileSetSummary> fromFiles(List<File> files) async {
    int totalBytes = 0;
    final Map<FileIconType, int> counts = {};
    for (final File file in files) {
      if (await file.exists()) {
        totalBytes += await file.length();
      }
      final FileIconType format =
          FileIconType.fromFileName(p.basename(file.path));
      counts[format] = (counts[format] ?? 0) + 1;
    }
    final List<({FileIconType format, int count})> formatCounts = [
      for (final entry in counts.entries)
        (format: entry.key, count: entry.value),
    ]..sort((a, b) {
        final int byCount = b.count.compareTo(a.count);
        return byCount != 0 ? byCount : a.format.index - b.format.index;
      });
    return FileSetSummary(
      fileCount: files.length,
      totalBytes: totalBytes,
      formatCounts: formatCounts,
    );
  }
}

/// Summary of the output directory: its new files and how many others
/// it holds.
class OutputSummary {
  const OutputSummary({
    required this.directory,
    required this.newFiles,
    required this.otherFileCount,
  });

  final Directory? directory;
  final FileSetSummary newFiles;
  final int otherFileCount;
}
