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
import 'package:url_launcher/url_launcher.dart';

enum SupportedTask {
  alignmentConcatenation,
  alignmentConversion,
  alignmentFiltering,
  alignmentSplitting,
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

const Map<String, CommonFileType> commonFileTypes = {
  'fasta': CommonFileType.sequence,
  'fa': CommonFileType.sequence,
  'fas': CommonFileType.sequence,
  'fsa': CommonFileType.sequence,
  'nexus': CommonFileType.sequence,
  'nex': CommonFileType.sequence,
  'phylip': CommonFileType.sequence,
  'phy': CommonFileType.sequence,
  'fastq': CommonFileType.sequence,
  'gz': CommonFileType.sequence,
  'gzip': CommonFileType.sequence,
  'csv': CommonFileType.tabulated,
  'txt': CommonFileType.plainText,
  'text': CommonFileType.plainText,
  'log': CommonFileType.plainText,
  'conf': CommonFileType.plainText,
  'toml': CommonFileType.plainText,
  'yaml': CommonFileType.plainText,
  'zip': CommonFileType.zip,
};

const Map<CommonFileType, String> commonFileIcons = {
  CommonFileType.sequence: 'assets/images/dna.svg',
  CommonFileType.plainText: 'assets/images/text.svg',
  CommonFileType.tabulated: 'assets/images/table.svg',
  CommonFileType.zip: 'assets/images/zip.svg',
  CommonFileType.other: 'assets/images/unknown.svg',
};

/// Common file type to match
/// file type with icons.
enum CommonFileType {
  sequence,
  plainText,
  tabulated,
  zip,
  other,
}

class FileAssociation extends FileUtils {
  FileAssociation({required this.file});

  final File file;

  bool get isSupportedViewExtension {
    final fileType = commonFileTYpe;
    return fileType == CommonFileType.plainText ||
        fileType == CommonFileType.tabulated;
  }

  CommonFileType get commonFileTYpe {
    String ext = _fileExtension;
    return commonFileTypes[ext] ?? CommonFileType.other;
  }

  String get matchingIcon {
    final fileType = commonFileTYpe;
    return commonFileIcons[fileType]!;
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
      final foundExtension = getFileExtension(file);
      if (type.extensions!.contains(foundExtension)) {
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

  String getFileExtension(File file) {
    final ext = p.extension(file.path);
    if (ext.isNotEmpty) {
      return ext.substring(1);
    }
    return '';
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

List<File> getNewFilesFromOutput(SegulOutputFile outputFiles) {
  return outputFiles.files
      .where((element) => element.isNew)
      .map((e) => e.file)
      .toList();
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
  const appDir = 'segui-data';
  final dir = await getApplicationDocumentsDirectory();
  final seguiDir = Directory(p.join(dir.path, appDir));
  if (!await seguiDir.exists()) {
    await seguiDir.create(recursive: true);
  }
  return seguiDir;
}

class UrlLauncherServices {
  const UrlLauncherServices({required this.file});

  final File file;

  Future<void> launchExternalApp() async {
    await launchUrl(_uri);
  }

  Future<bool> canLaunch() async {
    return await canLaunchUrl(_uri);
  }

  Uri get _uri {
    return Uri.file(file.path);
  }
}
