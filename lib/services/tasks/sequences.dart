import 'dart:io';

import 'package:segui/services/io.dart';
import 'package:segui/src/rust/api/sequence.dart';

class ConcatRunnerServices {
  const ConcatRunnerServices({
    required this.inputFiles,
    required this.inputFormat,
    required this.datatype,
    required this.outputDir,
    required this.outputPrefix,
    required this.outputFormat,
    required this.partitionFormat,
    required this.isCodonModel,
    required this.isInterleave,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFormat;
  final String datatype;
  final Directory outputDir;
  final String outputPrefix;
  final String outputFormat;
  final bool isInterleave;
  final String partitionFormat;
  final bool isCodonModel;

  Future<void> run() async {
    String outputFmt = getOutputFmt(outputFormat, isInterleave);
    String partitionFmt = getPartitionFmt(partitionFormat, isCodonModel);
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await AlignmentServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFormat,
      datatype: datatype,
      outputDir: outputDir.path,
    ).concatAlignment(
      outFname: outputPrefix,
      outFmtStr: outputFmt,
      partitionFmt: partitionFmt,
    );
  }
}

class AlignConversionRunnerServices {
  const AlignConversionRunnerServices({
    required this.inputFiles,
    required this.inputFormat,
    required this.datatype,
    required this.outputDir,
    required this.outputFormat,
    required this.isInterleave,
    required this.isSorted,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFormat;
  final String datatype;
  final Directory outputDir;
  final String outputFormat;
  final bool isInterleave;
  final bool isSorted;

  Future<void> run() async {
    String outputFmt = getOutputFmt(outputFormat, isInterleave);
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await SequenceServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFormat,
      datatype: datatype,
      outputDir: outputDir.path,
    ).convertSequence(
      outputFmt: outputFmt,
      sort: isSorted,
    );
  }
}

class PartConversionRunnerServices {
  const PartConversionRunnerServices({
    required this.inputFiles,
    required this.inputFormat,
    required this.datatype,
    required this.outputDir,
    required this.outputFormat,
    required this.isUnchecked,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFormat;
  final String datatype;
  final Directory outputDir;
  final String outputFormat;
  final bool isUnchecked;

  Future<void> run() async {
    final inputPartitions = inputFiles
        .where((e) => e.type == SegulType.alignmentPartition)
        .map((e) => e.file.path)
        .toList();
    await PartitionServices(
      inputFiles: inputPartitions,
      inputPartFmt: inputFormat,
      datatype: datatype,
      output: outputDir.path,
      outputPartFmt: outputFormat,
      isUncheck: isUnchecked,
    ).convertPartition();
  }
}

class SplitAlignmentRunner {
  const SplitAlignmentRunner({
    required this.inputFile,
    required this.inputFmt,
    required this.inputPartitionFmt,
    required this.inputPartition,
    required this.datatype,
    required this.outputDir,
    required this.prefix,
    required this.outputFmt,
    required this.isUncheck,
  });

  final String inputFile;
  final String inputFmt;
  final String inputPartitionFmt;
  final String inputPartition;
  final String datatype;
  final String outputDir;
  final String prefix;
  final String outputFmt;
  final bool isUncheck;

  Future<void> run() async {
    await SplitAlignmentServices(
      inputFile: inputFile,
      inputFmt: inputFmt,
      inputPartitionFmt: inputPartitionFmt,
      inputPartition: inputPartition,
      datatype: datatype,
      outputDir: outputDir,
      prefix: prefix,
      outputFmt: outputFmt,
      isUncheck: isUncheck,
    ).splitAlignment();
  }
}

class AlignmentSummaryRunner {
  const AlignmentSummaryRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputPrefix,
    required this.outputFmt,
    required this.interval,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputPrefix;
  final String outputFmt;
  final int interval;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    await AlignmentServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
    ).summarizeAlignment(
      outputPrefix: outputPrefix,
      interval: interval,
    );
  }
}

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
