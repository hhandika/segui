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

class SegulInputFile {
  SegulInputFile({
    required this.file,
    required this.type,
  });

  final SegulType type;
  final File file;

  factory SegulInputFile.fromXFile(XFile file, XTypeGroup xTypeGroup) {
    return SegulInputFile(
      file: File(file.path),
      type: matchTypeByXTypeGroup(xTypeGroup),
    );
  }

  factory SegulInputFile.addMoreFiles(SegulInputFile oldFile, XFile file) {
    return SegulInputFile(
      file: File(file.path),
      type: oldFile.type,
    );
  }
}

class SegulOutputFile {
  SegulOutputFile({
    required this.directory,
    required this.oldFiles,
    required this.newFiles,
  });

  final Directory? directory;
  final List<File> oldFiles;
  final List<File> newFiles;

  factory SegulOutputFile.empty() {
    return SegulOutputFile(
      directory: null,
      oldFiles: [],
      newFiles: [],
    );
  }

  factory SegulOutputFile.fromDirectory(Directory dir,
      {bool isRecursive = false}) {
    return SegulOutputFile(
      directory: dir,
      oldFiles: DirectoryCrawler(dir).crawl(recursive: isRecursive),
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

  // Update the list without accounting new files.
  factory SegulOutputFile.refresh(
      SegulOutputFile file, List<File> updatedFiles) {
    return SegulOutputFile(
      directory: file.directory,
      oldFiles: updatedFiles,
      newFiles: [],
    );
  }

  factory SegulOutputFile.deleteFile(SegulOutputFile oldFile, File file) {
    return SegulOutputFile(
      directory: oldFile.directory,
      oldFiles: oldFile.oldFiles..remove(file),
      newFiles: oldFile.newFiles,
    );
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
  uniformTypeIdentifiers: ['com.segui.partition', 'public.plain-text'],
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

/// Supported text file extensions.
/// Used to determine if a file is
/// a text file.
/// Allow segui to open text files
const List<String> supportedTextExtensions = [
  'txt',
  'text',
  'log',
  'conf',
  'toml',
  'yaml',
  'nex',
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

  final File file;

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

String getFileExtension(File file) {
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
        var results = _selectMultiUsingFilePicker(allowedExtension);
        _updateProvider(await results);
      } else {
        var results = _selectMultiFiles(allowedExtension);
        _updateProvider(await results);
      }
    } else {
      if (Platform.isAndroid) {
        final results = await _selectUsingFilePicker(allowedExtension);
        if (results != null) {
          _updateProvider([results]);
        }
      } else {
        final results = await _selectSingleFile(allowedExtension);
        if (results != null) {
          _updateProvider([XFile(results.file.path)]);
        }
      }
    }
  }

  Future<void> addDirectory() async {
    final result = Platform.isAndroid
        ? await _pickDirectoryFilePicker()
        : await _pickDirectory();

    if (result != null) {
      final files = DirectoryCrawler(result).crawlByType(allowedExtension);
      _updateProvider(files.map((e) => XFile(e.path)).toList());
    }
  }

  void _updateProvider(List<XFile> result) {
    final notifier = ref.read(fileInputProvider.notifier);
    if (result.isNotEmpty) {
      if (isAddNew) {
        notifier.addFiles(result, allowedExtension);
      } else {
        notifier.addMoreFiles(result, allowedExtension);
      }
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

  Future<List<XFile>> _selectMultiFiles(XTypeGroup allowedExtension) async {
    final fileList = await openFiles(
      acceptedTypeGroups: [allowedExtension],
    );
    return fileList;
  }

  List<SegulInputFile> mapFilesToSegulInputFile(
      List<XFile> files, XTypeGroup xTypeGroup) {
    return files.map((e) {
      return SegulInputFile(
        file: File(e.path),
        type: matchTypeByXTypeGroup(xTypeGroup),
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
            file: File(result.path),
            type: matchTypeByXTypeGroup(allowedExtension),
          );
  }

  // Do selection without data.
  Future<XFile?> _selectUsingFilePicker(XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.any);

    if (result == null) {
      return null;
    }
    return XFile(result.files.first.path!);
  }

  // Do selection without data.
  Future<List<XFile>> _selectMultiUsingFilePicker(
      XTypeGroup allowedExtension) async {
    final result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.any);

    if (result == null) {
      return [];
    }
    return result.files.map((e) => XFile(e.path!)).toList();
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
  final List<File> outputFiles;

  Future<File> write() async {
    String outputFilename = '${outputDir.path}.zip';
    String outputPath = p.join(outputDir.path, outputFilename);
    List<String> inputFiles = outputFiles.map((e) => e.path).toList();
    await ArchiveServices(
      inputFiles: inputFiles,
      outputPath: outputPath,
    ).zip();

    return File(outputPath);
  }
}

class IOServices {
  IOServices();

  Future<void> shareFile(BuildContext context, File file) async {
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile(file.path)],
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

  List<File> crawl({required bool recursive}) {
    return _findAllFilesInDir(dir, recursive);
  }

  List<File> crawlByType(XTypeGroup type) {
    List<File> inputFiles = [];
    dir.listSync(recursive: false).whereType<File>().forEach((e) {
      String extension = _getFileExtension(e);
      if (extension.isNotEmpty && type.extensions!.contains(extension)) {
        inputFiles.add(e);
      }
    });
    return inputFiles;
  }

  List<File> findNewFiles(List<File> oldFiles, bool isRecursive) {
    List<File> newFiles = [];
    dir.listSync(recursive: isRecursive).whereType<File>().forEach((e) {
      if (!oldFiles.any((oldFile) => oldFile.path == e.path)) {
        newFiles.add(e);
      }
    });

    return newFiles;
  }

  List<File> _findAllFilesInDir(Directory dir, bool isRecursive) {
    List<File> files =
        dir.listSync(recursive: isRecursive).whereType<File>().toList();
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
  Directory appDocDir = await getSeguiDirectory();
  String directory =
      dirName == null || dirName.isEmpty ? defaultOutputDir[task]! : dirName;
  Directory outputDir = Directory(p.join(appDocDir.path, directory));

  if (!await outputDir.exists()) {
    await outputDir.create(recursive: true);
  }

  return outputDir;
}

class FileUtils {
  FileUtils();

  Future<void> deleteFile(File file) async {
    await file.delete();
  }

  Future<int> calculateTotalSize(List<File> files) async {
    int totalSize = 0;
    for (var file in files) {
      totalSize += await file.length();
    }
    return totalSize;
  }

  Future<void> deleteFiles(List<File> files) async {
    for (var file in files) {
      await file.delete();
    }
  }
}

class DataUsageServices extends FileUtils {
  DataUsageServices();

  Future<({String count, String size})> calculateUsage() async {
    Directory appDocDir = await getSeguiDirectory();
    final files =
        appDocDir.listSync(recursive: true).whereType<File>().toList();
    final fileCount = files.length;
    final totalSize = await calculateTotalSize(files);
    return _getUsageText(fileCount, totalSize);
  }

  ({String count, String size}) _getUsageText(int fileCount, int totalSize) {
    return (count: '$fileCount files', size: formatSize(totalSize));
  }
}

class TempDataServices extends FileUtils {
  TempDataServices();

  Future<String> calculateAppTempDirUsage() async {
    final dir = await getTemporaryDirectory();
    final files = dir.listSync().whereType<File>().toList();
    final totalSize = await calculateTotalSize(files);
    return formatSize(totalSize);
  }

  Future<void> clearTempData() async {
    final dir = await getTemporaryDirectory();
    final files = dir.listSync().whereType<File>().toList();
    await deleteFiles(files);
  }
}

class FileMetadata {
  FileMetadata({
    required this.file,
  });

  final File file;

  Future<({String size, String lastModified})> get metadata async {
    String size = await _getSize(file);
    String lastModified = await _getLastModified(file);
    return (size: size, lastModified: lastModified);
  }

  Future<String> get metadataText async {
    final data = await metadata;
    return '${data.size} · modified ${data.lastModified}';
  }

// Count file size. Returns in kb, mb, or gb.
  Future<String> _getSize(File handler) async {
    int bytes = await handler.length();
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

String formatSize(int size) {
  double kb = size / 1024;
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

class FileCleaningService {
  FileCleaningService();

  Future<File?> removeAllFiles(List<File> files) async {
    final latestLogFile = _getTheLastLogFile(files);
    if (latestLogFile != null) {
      // remove latest log file from the list
      files.remove(latestLogFile);
    }
    _removeAll(files);

    return latestLogFile;
  }

  void _removeAll(List<File> files) {
    for (var file in files) {
      file.delete();
    }
  }

  File? _getTheLastLogFile(List<File> files) {
    FileLoggingService service = FileLoggingService();
    return service.findLatestLog(files);
  }
}

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

Future<Directory> getSeguiDirectory() async {
  const appDir = 'segui';
  final dir = await getApplicationDocumentsDirectory();
  final seguiDir = Directory(p.join(dir.path, appDir));
  if (!await seguiDir.exists()) {
    await seguiDir.create(recursive: true);
  }
  return seguiDir;
}
