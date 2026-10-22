import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/io.dart';
import 'package:path/path.dart' as p;

class SegulOutputFile {
  SegulOutputFile({
    required this.directory,
    required this.files,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now();

  final Directory? directory;
  final List<({File file, bool isNew})> files;

  /// When [directory] was selected. Files that appear or change later are
  /// new.
  final DateTime selectedAt;

  factory SegulOutputFile.empty() {
    return SegulOutputFile(
      directory: null,
      files: [],
    );
  }

  factory SegulOutputFile.fromDirectory(Directory dir,
      {required bool isRecursive}) {
    final DateTime selectedAt = DateTime.now();
    final DirectoryCrawler crawler = DirectoryCrawler(dir);
    return SegulOutputFile(
      directory: dir,
      files: isRecursive
          ? crawler.crawl(recursive: true)
          : [
              for (final file in crawler.crawlOutput())
                (file: file, isNew: false)
            ],
      selectedAt: selectedAt,
    );
  }

  factory SegulOutputFile.updateFiles(SegulOutputFile output) {
    return SegulOutputFile(
      directory: output.directory,
      files: DirectoryCrawler(output.directory!).findNewFiles(
        output.files,
        since: output.selectedAt,
      ),
      selectedAt: output.selectedAt,
    );
  }

  // Update the list without accounting new files.
  factory SegulOutputFile.refresh(
      SegulOutputFile file, List<File> updatedFiles) {
    List<({File file, bool isNew})> newFiles =
        updatedFiles.map((e) => (file: e, isNew: false)).toList();
    return SegulOutputFile(
      directory: file.directory,
      files: newFiles,
      selectedAt: file.selectedAt,
    );
  }

  factory SegulOutputFile.deleteFile(SegulOutputFile oldFile, File file) {
    return SegulOutputFile(
      directory: oldFile.directory,
      files: oldFile.files.where((f) => f.file.path != file.path).toList(),
      selectedAt: oldFile.selectedAt,
    );
  }
}

void updateOutputDir(WidgetRef ref, String dirName, SupportedTask task) {
  if (Platform.isAndroid || Platform.isIOS) {
    ref.read(fileOutputProvider.notifier).addMobile(
          dirName,
          SupportedTask.alignmentConcatenation,
        );
  }
}

Future<Directory> getOutputDir(String? dirName, SupportedTask task) async {
  Directory appDocDir = await getSeguiDirectory();
  String directory =
      dirName == null || dirName.isEmpty ? defaultOutputDir[task]! : dirName;
  Directory outputDir = Directory(p.join(appDocDir.path, directory));

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  return outputDir;
}
