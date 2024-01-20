import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/services/types.dart';
import 'package:share_plus/share_plus.dart';

enum SupportedTask {
  alignmentConcatenation,
  alignmentConversion,
  alignmentSummary,
  genomicRawReadSummary,
  genomicContigSummary,
  sequenceTranslation,
  sequenceUniqueId,
}

const Map<SupportedTask, String> defaultOutputDir = {
  SupportedTask.alignmentConcatenation: 'segui-alignment-concatenation',
  SupportedTask.alignmentConversion: 'segui-alignment-conversion',
  SupportedTask.alignmentSummary: 'segui-alignment-summary',
  SupportedTask.genomicRawReadSummary: 'segui-genomic-raw-read-summary',
  SupportedTask.genomicContigSummary: 'segui-genomic-contig-summary',
  SupportedTask.sequenceTranslation: 'segui-sequence-translation',
  SupportedTask.sequenceUniqueId: 'segui-sequence-unique-id',
};

enum SegulType {
  genomicReads,
  genomicContig,
  standardSequence,
  alignmentPartition,
}

/// A group of file extensions and uniform type identifiers.
/// Used to filter files by type.
class SegulInputFile {
  SegulInputFile({
    required this.file,
    required this.type,
  });

  final SegulType type;
  final XFile file;
}

class SegulOutputFile {
  SegulOutputFile({
    required this.directory,
    required this.oldFiles,
    required this.newFiles,
  });

  final Directory? directory;
  final List<XFile> oldFiles;
  final List<XFile> newFiles;

  factory SegulOutputFile.empty() {
    return SegulOutputFile(
      directory: null,
      oldFiles: [],
      newFiles: [],
    );
  }

  factory SegulOutputFile.fromDirectory(Directory dir) {
    return SegulOutputFile(
      directory: dir,
      oldFiles: DirectoryCrawler(dir).crawl(),
      newFiles: [],
    );
  }

  factory SegulOutputFile.updateFiles(
    SegulOutputFile oldFile,
  ) {
    return SegulOutputFile(
        directory: oldFile.directory,
        oldFiles: oldFile.oldFiles,
        newFiles: DirectoryCrawler(oldFile.directory!).findNewFiles(
          oldFile.oldFiles,
        ));
  }
}

SegulType matchTypeByXTypeGroup(XTypeGroup xTypeGroup) {
  switch (xTypeGroup) {
    case genomicTypeGroup:
      return SegulType.genomicReads;
    case sequenceTypeGroup:
      return SegulType.standardSequence;
    case partitionTypeGroup:
      return SegulType.alignmentPartition;
    default:
      return SegulType.standardSequence;
  }
}

const XTypeGroup genomicTypeGroup = XTypeGroup(
  label: 'Sequence Read',
  extensions: ['fasta', 'fastq', 'gz', 'gzip'],
  uniformTypeIdentifiers: [
    'com.segui.genomicSequence',
    'com.segui.genomicGzipSequence'
  ],
);

const XTypeGroup sequenceTypeGroup = XTypeGroup(
  label: 'Alignment',
  extensions: [
    'fasta',
    'fa',
    'fas',
    'fsa',
    'nexus',
    'nex',
    'phylip',
    'phy',
  ],
  uniformTypeIdentifiers: [
    'com.segui.dnaSequence',
  ],
);

const XTypeGroup partitionTypeGroup = XTypeGroup(
  label: 'Partition',
  extensions: ['nexus', 'nex', 'txt', 'part', 'partition'],
  uniformTypeIdentifiers: [
    'com.segui.partition',
  ],
);

class FileSelectionServices {
  const FileSelectionServices(this.ref);

  final WidgetRef ref;

  Future<List<SegulInputFile>> selectFiles(
    XTypeGroup allowedExtension,
    bool allowMultiple,
  ) async {
    if (allowMultiple) {
      return _selectMultiFiles(allowedExtension);
    } else {
      final result = await _selectSingleFile(allowedExtension);
      return result == null ? [] : [result];
    }
  }

  Future<List<SegulInputFile>> _selectMultiFiles(
      XTypeGroup allowedExtension) async {
    final fileList = await openFiles(
      acceptedTypeGroups: [allowedExtension],
    );
    return fileList.map((e) {
      return SegulInputFile(
        file: e,
        type: matchTypeByXTypeGroup(allowedExtension),
      );
    }).toList();
  }

  Future<SegulInputFile?> _selectSingleFile(XTypeGroup allowedExtension) async {
    final result = await openFile(
      acceptedTypeGroups: [allowedExtension],
    );
    return result == null
        ? null
        : SegulInputFile(
            file: result,
            type: matchTypeByXTypeGroup(allowedExtension),
          );
  }
}

class IOServices {
  IOServices();

  Future<XFile> archiveOutput({
    required Directory dir,
    required String? fileName,
    required SupportedTask task,
  }) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String outputFilename = '${fileName ?? defaultOutputDir[task]!}.zip';
    String outputPath = p.join(appDocDir.path, outputFilename);

    ZipFileEncoder encoder = ZipFileEncoder();
    encoder.zipDirectory(
      dir,
      filename: outputPath,
    );

    return XFile(outputPath);
  }

  Future<void> shareFile(BuildContext context, XFile file) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [file],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
  }

  int countFiles(List<SegulInputFile> files, SegulType type) {
    return files.where((e) => e.type == type).length;
  }

  List<String> convertPathsToString(
      List<SegulInputFile> files, SegulType type) {
    return files.where((e) => e.type == type).map((e) => e.file.path).toList();
  }

  Future<Directory?> selectDir() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      if (kDebugMode) {
        print('Selected directory: $result');
      }
      return Directory(result);
    }
    return null;
  }
}

class DirectoryCrawler {
  DirectoryCrawler(this.dir);

  final Directory dir;

  List<XFile> crawl() {
    return _findAllFilesInDir(dir);
  }

  List<XFile> findNewFiles(List<XFile> oldFiles) {
    List<XFile> newFiles = _findAllFilesInDir(dir);
    newFiles.removeWhere((e) => oldFiles.contains(e));
    return newFiles;
  }

  List<XFile> _findAllFilesInDir(Directory dir) {
    List<XFile> files = dir
        .listSync(recursive: false)
        .whereType<File>()
        .map((e) => XFile(e.path))
        .toList();
    return files;
  }
}

PlatformType get runningPlatform {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformType.isMobile;
  } else {
    return PlatformType.isDesktop;
  }
}

Future<String> getOutputDir(String outputCtr, SupportedTask task) async {
  if (Platform.isIOS || outputCtr.isEmpty) {
    return getOutputDirForTask(outputCtr, task);
  } else {
    return outputCtr;
  }
}

Future<String> getOutputDirForTask(String dir, SupportedTask task) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String directory = dir.isEmpty ? defaultOutputDir[task]! : dir;
  Directory outputDir = Directory(p.join(appDocDir.path, directory));

  return outputDir.path;
}

// Count file size. Returns in kb, mb, or gb.
Future<String> getFileSize(XFile path) async {
  File file = File(path.path);
  int bytes = await file.length();
  double kb = bytes / 1024;
  double mb = kb / 1024;
  double gb = mb / 1024;
  if (gb >= 1) {
    return '${gb.toStringAsFixed(2)} Gb';
  } else if (mb >= 1) {
    return '${mb.toStringAsFixed(2)} Mb';
  } else {
    return '${kb.toStringAsFixed(2)} Kb';
  }
}

String showOutputDir(String outputDir) {
  if (Platform.isIOS) {
    return 'On My Devices/segui';
  } else {
    return outputDir;
  }
}

String getOutputFmt(String outputFormat, bool isInterleave) {
  if (isInterleave) {
    return '$outputFormat-int';
  } else {
    return outputFormat;
  }
}

String getPartitionFmt(String partitionFormat, bool isCodon) {
  if (isCodon) {
    return '$partitionFormat-codon';
  } else {
    return partitionFormat;
  }
}
