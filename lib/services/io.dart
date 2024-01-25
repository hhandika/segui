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
  alignmentFiltering,
  alignmentSplit,
  alignmentSummary,
  genomicRawReadSummary,
  genomicContigSummary,
  partitionConversion,
  sequenceExtraction,
  sequenceRemoval,
  sequenceRenaming,
  sequenceUniqueId,
  sequenceTranslation,
}

const Map<SupportedTask, String> defaultOutputDir = {
  SupportedTask.alignmentConcatenation: 'segui-alignment-concatenation',
  SupportedTask.alignmentConversion: 'segui-alignment-conversion',
  SupportedTask.alignmentFiltering: 'segui-alignment-filtering',
  SupportedTask.alignmentSplit: 'segui-alignment-split',
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

/// Match all file extensions,
/// Use mostly for determining file
/// input.
enum SegulType {
  genomicReads,
  genomicContig,
  standardSequence,
  alignmentPartition,
  plainText,
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
    bool isRecursive,
  ) {
    return SegulOutputFile(
        directory: oldFile.directory,
        oldFiles: oldFile.oldFiles,
        newFiles: DirectoryCrawler(oldFile.directory!)
            .findNewFiles(oldFile.oldFiles, isRecursive));
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
    case plainTextTypeGroup:
      return SegulType.plainText;
    default:
      return SegulType.standardSequence;
  }
}

const XTypeGroup plainTextTypeGroup = XTypeGroup(
  label: 'Text',
  extensions: ['txt', 'text'],
  uniformTypeIdentifiers: [
    'public.plain-text',
  ],
);

const XTypeGroup genomicTypeGroup = XTypeGroup(
  label: 'Sequence Read',
  extensions: ['fasta', 'fsa', 'fa', 'fna', 'fastq', 'fq', 'gz', 'gzip'],
  uniformTypeIdentifiers: [
    'com.segui.genomicSequence',
    'org.gnu.gnu-zip-archive'
  ],
);

const XTypeGroup sequenceTypeGroup = XTypeGroup(
  label: 'Sequence',
  extensions: [
    'fasta',
    'fa',
    'fas',
    'fsa',
    'fna',
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

const List<String> sequenceExtensions = [
  'fasta',
  'fa',
  'fas',
  'fsa',
  'nexus',
  'nex',
  'phylip',
  'phy',
  'fastq',
  'gz',
  'gzip'
];

const List<String> tabularExtensions = [
  'csv',
];

const List<String> supportedTextExtensions = [
  'txt',
  'text',
];

/// Common file type to match
/// file type with icons.
enum CommonFileType {
  sequence,
  plainText,
  tabulated,
  other,
}

class FileAssociation {
  FileAssociation({required this.file});

  final XFile file;

  bool get isSupportedViewerExtension {
    final fileType = commonFileTYpe;
    return fileType == CommonFileType.plainText ||
        fileType == CommonFileType.tabulated;
  }

  CommonFileType get commonFileTYpe {
    String ext = _fileExtension;
    if (sequenceExtensions.contains(ext)) {
      return CommonFileType.sequence;
    } else if (tabularExtensions.contains(ext)) {
      return CommonFileType.tabulated;
    } else if (supportedTextExtensions.contains(ext)) {
      return CommonFileType.plainText;
    } else {
      return CommonFileType.other;
    }
  }

  String get matchingIcon {
    switch (commonFileTYpe) {
      case CommonFileType.sequence:
        return 'assets/images/dna.svg';
      case CommonFileType.plainText:
        return 'assets/images/text.svg';
      case CommonFileType.tabulated:
        return 'assets/images/table.svg';
      case CommonFileType.other:
        return 'assets/images/unknown.svg';
    }
  }

  bool get isSequenceFile {
    return sequenceExtensions.contains(_fileExtension);
  }

  bool get isTabularFile {
    return tabularExtensions.contains(_fileExtension);
  }

  String get _fileExtension {
    return getFileExtension(file);
  }
}

String getFileExtension(XFile file) {
  return p.extension(file.path).substring(1);
}

class FileInputServices {
  const FileInputServices(
    this.ref, {
    required this.allowedExtension,
    required this.allowMultiple,
    required this.isAddNew,
  });

  final WidgetRef ref;
  final XTypeGroup allowedExtension;
  final bool allowMultiple;
  final bool isAddNew;

  Future<void> selectFiles() async {
    if (allowMultiple) {
      if (Platform.isAndroid) {
        var results = _selectMultiFileAndroid(allowedExtension);
        _updateProvider(await results);
      } else {
        var results = _selectMultiFiles(allowedExtension);
        _updateProvider(await results);
      }
    } else {
      if (Platform.isAndroid) {
        final results = await _selectSingleFileAndroid(allowedExtension);
        if (results != null) {
          _updateProvider([results]);
        }
      } else {
        final results = await _selectSingleFile(allowedExtension);
        if (results != null) {
          _updateProvider([results]);
        }
      }
    }
  }

  Future<void> addDirectory() async {
    final result = Platform.isAndroid
        ? await _pickDirectory()
        : await _pickDirectoryFilePicker();

    if (result != null) {
      final files = DirectoryCrawler(result).crawlByType(allowedExtension);
      _updateProvider(files);
    }
  }

  void _updateProvider(List<SegulInputFile> result) {
    final notifier = ref.read(fileInputProvider.notifier);
    if (result.isNotEmpty) {
      isAddNew ? notifier.addFiles(result) : notifier.addMoreFiles(result);
    }
  }

  Future<Directory?> _pickDirectory() async {
    final result = await getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
  }

  Future<Directory?> _pickDirectoryFilePicker() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      return Directory(result);
    }
    return null;
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

  List<SegulInputFile> crawlByType(XTypeGroup type) {
    List<SegulInputFile> inputFiles = [];
    dir.listSync(recursive: false).whereType<File>().forEach((e) {
      String extension = _getFileExtension(e);
      if (extension.isNotEmpty && type.extensions!.contains(extension)) {
        final filePath = e.path;
        inputFiles.add(SegulInputFile(
          file: XFile(filePath),
          type: matchTypeByXTypeGroup(type),
        ));
      }
    });
    return inputFiles;
  }

  List<XFile> findNewFiles(List<XFile> oldFiles, bool isRecursive) {
    List<XFile> newFiles = [];
    dir.listSync(recursive: isRecursive).whereType<File>().forEach((e) {
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

  String _getFileExtension(File file) {
    return p.extension(file.path).substring(1);
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

class FileMetadata {
  FileMetadata({
    required this.file,
  });

  final XFile file;

  Future<({String size, String lastModified})> get metadata async {
    File handler = File(file.path);
    String size = await getSize(handler);
    String lastModified = await getLastModified(handler);
    return (size: size, lastModified: lastModified);
  }

// Count file size. Returns in kb, mb, or gb.
  Future<String> getSize(File handler) async {
    int bytes = await handler.length();
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

  Future<String> getLastModified(File handler) async {
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
