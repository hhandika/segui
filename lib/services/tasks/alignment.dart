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
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
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

enum FilteringOptions {
  minimalTaxa,
  minimalLength,
  parsimonyInf,
  percentParsimonyInf
}

const Map<FilteringOptions, String> filteringOptions = {
  FilteringOptions.minimalTaxa: 'Minimal taxa',
  FilteringOptions.minimalLength: 'Minimal length',
  FilteringOptions.parsimonyInf: 'Parsimony informative sites',
  FilteringOptions.percentParsimonyInf: 'Percentage of informative sites'
};

class FilteringRunner {
  const FilteringRunner({
    required this.inputFiles,
    required this.inputFormat,
    required this.datatype,
    required this.outputDir,
    required this.isConcatenated,
    required this.filteringOptions,
    required this.paramValue,
    required this.outputPrefix,
    required this.outputFormat,
    required this.partitionFormat,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFormat;
  final String datatype;
  final Directory outputDir;
  final bool isConcatenated;
  final FilteringOptions filteringOptions;
  final String paramValue;
  final String? outputPrefix;
  final String? outputFormat;
  final String? partitionFormat;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    final filter = FilteringServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFormat,
      datatype: datatype,
      outputDir: outputDir.path,
      isConcat: isConcatenated,
      params: _matchParams(),
      prefix: outputPrefix,
      outputFmt: outputFormat,
      partitionFmt: partitionFormat,
    );

    await filter.filter();
  }

  FilteringParams _matchParams() {
    switch (filteringOptions) {
      case FilteringOptions.minimalTaxa:
        return FilteringParams.minTax(double.tryParse(paramValue) ?? 0);
      case FilteringOptions.minimalLength:
        return FilteringParams.alnLen(int.parse(paramValue));
      case FilteringOptions.parsimonyInf:
        return FilteringParams.parsInf(int.parse(paramValue));
      case FilteringOptions.percentParsimonyInf:
        return FilteringParams.percInf(double.tryParse(paramValue) ?? 0);
      default:
        throw ArgumentError('Invalid filtering option');
    }
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
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
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
    if (inputPartitions.isEmpty) {
      throw 'No input files';
    }
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
    required this.interval,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputPrefix;
  final int interval;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
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
