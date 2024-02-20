import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/services/io/directory.dart';
import 'package:segui/services/io/io.dart';
import 'package:path/path.dart' as p;

class SegulOutputFile {
  SegulOutputFile({
    required this.directory,
    required this.files,
  });

  final Directory? directory;
  final List<({File file, bool isNew})> files;

  factory SegulOutputFile.empty() {
    return SegulOutputFile(
      directory: null,
      files: [],
    );
  }

  factory SegulOutputFile.fromDirectory(Directory dir,
      {required bool isRecursive}) {
    return SegulOutputFile(
      directory: dir,
      files: DirectoryCrawler(dir).crawl(recursive: isRecursive),
    );
  }

  factory SegulOutputFile.updateFiles(SegulOutputFile output,
      {required bool isRecursive}) {
    return SegulOutputFile(
        directory: output.directory,
        files: DirectoryCrawler(output.directory!)
            .findNewFiles(output.files, isRecursive));
  }

  // Update the list without accounting new files.
  factory SegulOutputFile.refresh(
      SegulOutputFile file, List<File> updatedFiles) {
    List<({File file, bool isNew})> newFiles =
        updatedFiles.map((e) => (file: e, isNew: false)).toList();
    return SegulOutputFile(
      directory: file.directory,
      files: newFiles,
    );
  }

  factory SegulOutputFile.deleteFile(SegulOutputFile oldFile, File file) {
    return SegulOutputFile(
      directory: oldFile.directory,
      files: oldFile.files.where((f) => f.file.path != file.path).toList(),
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
