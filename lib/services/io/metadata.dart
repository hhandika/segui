import 'dart:io';

import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

class FileMetadata extends FileUtils {
  FileMetadata({
    required this.file,
  });

  final File file;

  Future<({String size, String lastModified})> get metadata async {
    String size = await _getSize();
    String lastModified = await _getLastModified(file);
    return (size: size, lastModified: lastModified);
  }

  Future<CompleteFileMetadata> get completeMetadata async {
    final stats = await file.stat();
    return CompleteFileMetadata(
      size: formatSize(stats.size),
      lastModified: formatTimestamp(stats.modified),
      accessed: formatTimestamp(stats.accessed),
      path: file.path,
      name: getBaseName(file),
      fileExtension: file.fileExtension.toUpperCase(),
    );
  }

  Future<String> get metadataText async {
    final data = await metadata;
    return '${data.size} · modified ${data.lastModified}';
  }

// Count file size. Returns in kb, mb, or gb.
  Future<String> _getSize() async {
    int bytes = await file.length();
    return formatSize(bytes);
  }

  Future<String> _getLastModified(File handler) async {
    DateTime lastModified = await handler.lastModified();
    DateTime now = DateTime.now();
    // Format to show days to seconds ago.
    Duration duration = now.difference(lastModified);
    if (duration.inDays > 365) {
      return '${duration.inDays ~/ 365} years ago';
    } else if (duration.inDays > 30) {
      return '${duration.inDays ~/ 30} months ago';
    } else if (duration.inDays > 0) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minutes ago';
    } else if (duration.inSeconds > 0) {
      return '${duration.inSeconds} seconds ago';
    } else {
      return 'just now';
    }
  }
}

class CompleteFileMetadata {
  const CompleteFileMetadata({
    required this.size,
    required this.lastModified,
    required this.path,
    required this.accessed,
    required this.name,
    required this.fileExtension,
  });

  final String size;
  final String lastModified;
  final String accessed;
  final String path;
  final String name;
  final String fileExtension;
}
