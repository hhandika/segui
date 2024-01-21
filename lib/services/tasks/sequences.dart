import 'dart:io';

import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class SequenceIdExtractionRunner {
  const SequenceIdExtractionRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.prefix,
    required this.isMap,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String prefix;
  final bool isMap;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await SequenceServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
    ).parseSequenceId(
      isMap: isMap,
      outputFname: prefix,
    );
  }
}

class SequenceTranslationRunner {
  const SequenceTranslationRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.tableIndex,
    required this.readingFrame,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFmt;
  final int tableIndex;
  final String readingFrame;

  Future<void> run() async {
    String table = '${tableIndex + 1}';
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await SequenceServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
    ).translateSequence(
      outputFmt: outputFmt,
      table: table,
      readingFrame: int.tryParse(readingFrame) ?? 1,
    );
  }
}
