import 'dart:io';
import 'package:file_selector/file_selector.dart';
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

class IOServices {
  IOServices();

  Future<File> archiveOutput({
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

    return File(outputPath);
  }

  Future<void> shareFile(BuildContext context, File file) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path)],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
    );
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

  Future<List<XFile>> pickMultiFiles(List<XTypeGroup> allowedExtension) async {
    final fileList = await openFiles(
      acceptedTypeGroups: allowedExtension,
    );
    return fileList;
  }

  Future<File?> selectFile(List<String>? allowedExtension) async {
    final result = await _matchPicker(allowedExtension);

    if (result != null) {
      if (kDebugMode) {
        print('Selected file: ${result.files.single.path}');
      }
      return File(result.files.single.path!);
    }
    return null;
  }

  Future<List<File>> selectMultiFiles(List<String> allowedExtension) async {
    FilePickerResult? files = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: allowedExtension,
    );

    if (files != null) {
      return files.paths.map((e) => File(e!)).toList();
    } else {
      return [];
    }
  }

  Future<FilePickerResult?> _matchPicker(List<String>? allowedExt) async {
    if (allowedExt == null) {
      return await FilePicker.platform.pickFiles();
    }

    return await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExt,
    );
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
