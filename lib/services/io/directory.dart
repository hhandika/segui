import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';

const Map<SupportedTask, String> defaultOutputDir = {
  SupportedTask.alignmentConcatenation: 'segui-alignment-concatenation',
  SupportedTask.alignmentConversion: 'segui-alignment-conversion',
  SupportedTask.alignmentFiltering: 'segui-alignment-filtering',
  SupportedTask.alignmentSplitting: 'segui-alignment-split',
  SupportedTask.alignmentSummary: 'segui-alignment-summary',
  SupportedTask.genomicRawReadSummary: 'segui-genomic-raw-read-summary',
  SupportedTask.genomicContigSummary: 'segui-genomic-contig-summary',
  SupportedTask.partitionConversion: 'segui-partition-conversion',
  SupportedTask.sequenceExtraction: 'segui-sequence-extraction',
  SupportedTask.sequenceRemoval: 'segui-sequence-removal',
  SupportedTask.sequenceRenaming: 'segui-sequence-renaming',
  SupportedTask.sequenceUniqueId: 'segui-sequence-unique-id',
  SupportedTask.sequenceTranslation: 'segui-sequence-translation',
};

class DirectorySelectionServices {
  const DirectorySelectionServices(this.ref);

  final WidgetRef ref;

  Future<void> addOutputDir() async {
    final result = await _getDirectory();
    if (result != null) {
      ref.read(fileOutputProvider.notifier).add(result);
    }
  }

  Future<Directory?> _getDirectory() async {
    final result = await getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
  }
}

class DirectoryCrawler extends FileUtils {
  DirectoryCrawler(this.dir);

  final Directory dir;

  List<({File file, bool isNew})> crawl({required bool recursive}) {
    const bool isNew = false;
    return _findAllFilesInDir(dir, recursive, isNew);
  }

  List<File> crawlByType(XTypeGroup type) {
    List<File> inputFiles = [];
    List<File> foundFiles =
        dir.listSync(recursive: true).whereType<File>().toList();
    // Filter files by matching type.
    for (var file in foundFiles) {
      if (type.extensions!.contains(file.fileExtension)) {
        inputFiles.add(file);
      }
    }
    return inputFiles;
  }

  List<({File file, bool isNew})> findNewFiles(
      List<({File file, bool isNew})> oldFiles, bool isRecursive) {
    const bool isNew = true;
    List<({File file, bool isNew})> destination = [];
    List<File> origin = oldFiles.map((e) => e.file).toList();

    List<({File file, bool isNew})> allFiles =
        _findAllFilesInDir(dir, isRecursive, isNew);
    for (var file in allFiles) {
      if (!origin.any((p) => p.path == file.file.path)) {
        if (kDebugMode) {
          print('Found file: ${file.file.path}');
        }
        destination.add(file);
      }
    }
    destination.addAll(oldFiles);
    return destination;
  }

  List<({File file, bool isNew})> _findAllFilesInDir(
      Directory dir, bool isRecursive, bool isNew) {
    List<FileSystemEntity> founds = dir.listSync(recursive: isRecursive);
    List<({File file, bool isNew})> files = [];
    for (var file in founds) {
      if (file is File) {
        if (kDebugMode) {
          print('Found file: ${file.path}');
        }
        files.add((file: file, isNew: isNew));
      }
    }
    return files;
  }
}
