import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/archive.dart';
import 'package:share_plus/share_plus.dart';

enum SupportedTask {
  alignmentConcatenation,
  alignmentConversion,
  alignmentSplit,
  alignmentSummary,
  genomicRawReadSummary,
  genomicContigSummary,
  partitionConversion,
  sequenceTranslation,
  sequenceUniqueId,
}

const Map<SupportedTask, String> defaultOutputDir = {
  SupportedTask.alignmentConcatenation: 'segui-alignment-concatenation',
  SupportedTask.alignmentConversion: 'segui-alignment-conversion',
  SupportedTask.alignmentSplit: 'segui-alignment-split',
  SupportedTask.alignmentSummary: 'segui-alignment-summary',
  SupportedTask.genomicRawReadSummary: 'segui-genomic-raw-read-summary',
  SupportedTask.genomicContigSummary: 'segui-genomic-contig-summary',
  SupportedTask.partitionConversion: 'segui-partition-conversion',
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
      if (Platform.isAndroid) {
        return _selectMultiFileAndroid(allowedExtension);
      } else {
        return _selectMultiFiles(allowedExtension);
      }
    } else {
      if (Platform.isAndroid) {
        final results = await _selectSingleFileAndroid(allowedExtension);
        return results == null ? [] : [results];
      } else {
        return _selectSingleFile(allowedExtension).then((value) {
          return value == null ? [] : [value];
        });
      }
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

  Future<List<SegulInputFile>> _selectMultiFileAndroid(
      XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any);

    return result == null
        ? []
        : result.files.map((e) {
            return SegulInputFile(
              file: XFile(e.path!),
              type: matchTypeByXTypeGroup(allowedExtension),
            );
          }).toList();
  }

  Future<SegulInputFile?> _selectSingleFileAndroid(
      XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      type: FileType.any,
    );

    return result == null
        ? null
        : SegulInputFile(
            file: XFile(result.files.single.path!),
            type: matchTypeByXTypeGroup(allowedExtension),
          );
  }
}

class ArchiveRunner {
  const ArchiveRunner({
    required this.outputDir,
    required this.outputFiles,
  });

  final Directory outputDir;
  final List<XFile> outputFiles;

  Future<XFile> write() async {
    String outputFilename = '${outputDir.path}.zip';
    String outputPath = p.join(outputDir.path, outputFilename);
    List<String> inputFiles = outputFiles.map((e) => e.path).toList();
    await ArchiveServices(
      inputDirectory: outputDir.path,
      inputFiles: inputFiles,
      outputPath: outputPath,
    ).zip();

    return XFile(outputPath);
  }
}

class IOServices {
  IOServices();

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
    List<XFile> newFiles = [];

    dir.listSync(recursive: false).whereType<File>().forEach((e) {
      if (!oldFiles.any((oldFile) => oldFile.path == e.path)) {
        newFiles.add(XFile(e.path));
      }
    });

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

void updateOutputDir(WidgetRef ref, String dirName, SupportedTask task) {
  if (Platform.isAndroid || Platform.isIOS) {
    ref.read(fileOutputProvider.notifier).addMobile(
          dirName,
          SupportedTask.alignmentConcatenation,
        );
  }
}

Future<Directory> getOutputDir(String? dirName, SupportedTask task) async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  String directory =
      dirName == null || dirName.isEmpty ? defaultOutputDir[task]! : dirName;
  Directory outputDir = Directory(p.join(appDocDir.path, directory));

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  return outputDir;
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

String showOutputDir(Directory directory) {
  if (Platform.isIOS) {
    return 'On My Devices/segui';
  } else {
    return directory.path;
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
