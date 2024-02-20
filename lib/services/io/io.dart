import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/logging.dart';
import 'package:segui/services/io/output.dart';
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

PlatformType get runningPlatform {
  if (Platform.isAndroid || Platform.isIOS) {
    return PlatformType.isMobile;
  } else {
    return PlatformType.isDesktop;
  }
}

class FileUtils {
  FileUtils();

  Future<void> deleteFile(File file) async {
    await file.delete();
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

  String formatTimestamp(DateTime date) {
    final format = DateFormat.yMd().add_jm().format(date);
    return format.toString();
  }

  String getBaseName(File file) {
    return p.basename(file.path);
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
