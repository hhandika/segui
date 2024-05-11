import 'dart:io';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/src/rust/api/contig.dart';
import 'package:segui/src/rust/api/reads.dart';

class ContigSummaryRunner {
  const ContigSummaryRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.outputDir,
    required this.prefix,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String prefix;
  final Directory outputDir;

  Future<void> run() async {
    List<String> finalInputFiles =
        IOServices().convertPathsToString(inputFiles, SegulType.genomicContig);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }

    await ContigServices(
      files: finalInputFiles,
      fileFmt: inputFmt,
      outputDir: outputDir.path,
    ).summarize(prefix: prefix.isEmpty ? null : prefix);
  }
}

class ReadSummaryRunner {
  const ReadSummaryRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.outputDir,
    required this.prefix,
    required this.mode,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final Directory outputDir;
  final String prefix;
  final String mode;

  Future<void> run() async {
    List<String> finalInputFiles =
        IOServices().convertPathsToString(inputFiles, SegulType.genomicReads);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    await RawReadServices(
      files: finalInputFiles,
      fileFmt: inputFmt,
      outputDir: outputDir.path,
    ).summarize(mode: mode, prefix: prefix.isEmpty ? null : prefix);
  }
}
