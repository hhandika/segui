import 'dart:io';

import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/types.dart';
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
      prefix: outputPrefix,
      outFmtStr: outputFmt,
      partitionFmt: partitionFmt,
    );
  }
}

enum FilteringOptions {
  minimalTaxa,
  minimalLength,
  maximalLength,
  parsimonyInf,
  maximalParsimonyInf,
  percentParsimonyInf,
  missingData,
}

const Map<FilteringOptions, String> filteringOptions = {
  FilteringOptions.minimalTaxa: 'Minimal taxa',
  FilteringOptions.minimalLength: 'Minimal length',
  FilteringOptions.maximalLength: 'Maximal length',
  FilteringOptions.parsimonyInf: 'Parsimony informative sites',
  FilteringOptions.maximalParsimonyInf: 'Maximal parsimony informative sites',
  FilteringOptions.percentParsimonyInf: 'Percentage of informative sites',
  FilteringOptions.missingData: 'Maximal missing data',
};

/// Whether [value] parses to a proportion between 0 and 1, inclusive.
bool isValidProportion(String value) {
  final double? number = double.tryParse(value.trim());
  return number != null && number >= 0 && number <= 1;
}

/// Whether [value] parses to a whole number of zero or more.
bool isValidCount(String value) {
  final int? number = int.tryParse(value.trim());
  return number != null && number >= 0;
}

/// Whether [value] is a valid parameter for the filtering [option].
bool isValidFilteringValue(FilteringOptions option, String value) {
  switch (option) {
    case FilteringOptions.minimalTaxa:
    case FilteringOptions.percentParsimonyInf:
    case FilteringOptions.missingData:
      return isValidProportion(value);
    case FilteringOptions.minimalLength:
    case FilteringOptions.maximalLength:
    case FilteringOptions.parsimonyInf:
    case FilteringOptions.maximalParsimonyInf:
      return isValidCount(value);
  }
}

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
        return FilteringParams.alnLen(BigInt.parse(paramValue));
      case FilteringOptions.maximalLength:
        return FilteringParams.maxAlnLen(BigInt.parse(paramValue));
      case FilteringOptions.parsimonyInf:
        return FilteringParams.parsInf(BigInt.parse(paramValue));
      case FilteringOptions.maximalParsimonyInf:
        return FilteringParams.maxParsInf(BigInt.parse(paramValue));
      case FilteringOptions.percentParsimonyInf:
        return FilteringParams.percInf(double.tryParse(paramValue) ?? 0);
      case FilteringOptions.missingData:
        return FilteringParams.missingData(double.parse(paramValue));
    }
  }
}

class ConversionRunnerServices {
  const ConversionRunnerServices({
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
    await SequenceConversionServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFormat,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: outputFmt,
      sort: isSorted,
    ).convertSequence();
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
      prefix: prefix.isEmpty ? null : prefix,
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
    this.isPerLocus = false,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputPrefix;
  final BigInt interval;

  /// Write one summary file per locus instead of a combined summary.
  final bool isPerLocus;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    final services = AlignmentServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
    );
    if (isPerLocus) {
      await services.summarizeAlignmentPerLocus(
        outputPrefix: outputPrefix.isEmpty ? null : outputPrefix,
      );
    } else {
      await services.summarizeAlignment(
        outputPrefix: outputPrefix,
        interval: interval,
      );
    }
  }
}

/// Whether [value] is a single character to split sample names on.
bool isValidGroupDelimiter(String value) {
  return value.runes.length == 1;
}

/// Whether [value] is a field count of one or more.
bool isValidGroupFields(String value) {
  final int? number = int.tryParse(value.trim());
  return number != null && number >= 1;
}

/// Whether [value] is a non-empty, well-formed regular expression.
/// SEGUL uses the Rust regex syntax, so some patterns that pass here,
/// such as lookarounds, are still rejected when the groups are previewed.
bool isValidGroupRegex(String value) {
  if (value.isEmpty) {
    return false;
  }
  try {
    RegExp(value);
    return true;
  } on FormatException {
    return false;
  }
}

/// How samples are assigned to groups for group mean distances.
class DistanceGrouping {
  const DistanceGrouping({
    required this.method,
    this.delimiter = '',
    this.fields = '',
    this.pattern = '',
  });

  const DistanceGrouping.none() : this(method: 'none');

  /// A key of [distanceGroupingMethods].
  final String method;
  final String delimiter;
  final String fields;
  final String pattern;

  bool get isEnabled => method != 'none';

  /// Whether the grouping parameters are complete. A group file must be
  /// among [inputFiles] when [method] is `file`.
  bool isValid(List<SegulInputFile> inputFiles) {
    switch (method) {
      case 'delimiter':
        return isValidGroupDelimiter(delimiter) && isValidGroupFields(fields);
      case 'regex':
        return isValidGroupRegex(pattern);
      case 'file':
        return _groupFiles(inputFiles).length == 1;
      default:
        return true;
    }
  }

  DistanceGroupingParams toParams(List<SegulInputFile> inputFiles) {
    switch (method) {
      case 'auto':
        return const DistanceGroupingParams.auto();
      case 'delimiter':
        return DistanceGroupingParams.delimiter(
          delimiter: delimiter,
          fields: BigInt.parse(fields.trim()),
        );
      case 'regex':
        return DistanceGroupingParams.regex(pattern);
      case 'file':
        final files = _groupFiles(inputFiles);
        if (files.length != 1) {
          throw 'Select one group file.';
        }
        return DistanceGroupingParams.mapFile(files.first);
      default:
        return const DistanceGroupingParams.none();
    }
  }

  List<String> _groupFiles(List<SegulInputFile> inputFiles) {
    return IOServices().convertPathsToString(inputFiles, SegulType.sampleGroup);
  }
}

class AlignmentDistanceRunner {
  const AlignmentDistanceRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.prefix,
    required this.model,
    required this.triangle,
    required this.diagonal,
    this.grouping = const DistanceGrouping.none(),
    this.isLongFormat = false,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String prefix;

  /// A key of [distanceModels].
  final String model;

  /// A key of [distanceMatrixTriangles].
  final String triangle;

  /// A key of [distanceMatrixDiagonals].
  final String diagonal;

  final DistanceGrouping grouping;

  /// Whether to also write long-format tables of all loci.
  final bool isLongFormat;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    await AlignmentDistanceServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      model: model,
      triangle: triangle,
      diagonal: diagonal,
      prefix: prefix.isEmpty ? null : prefix,
      grouping: grouping.toParams(inputFiles),
      longFormat: isLongFormat,
    ).computeDistance();
  }
}

/// Assigns the samples of the input alignments to groups without computing
/// distances, so users can check the groups before running.
class DistanceGroupPreviewRunner {
  const DistanceGroupPreviewRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.grouping,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final DistanceGrouping grouping;

  Future<DistanceGroupPreview> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    return await AlignmentDistanceServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: '',
      model: distanceModels.keys.first,
      triangle: distanceMatrixTriangles.keys.first,
      diagonal: distanceMatrixDiagonals.keys.first,
      grouping: grouping.toParams(inputFiles),
      longFormat: false,
    ).previewGroups();
  }
}

enum TrimmingOptions { missingData, parsimonyInf }

const Map<TrimmingOptions, String> trimmingOptions = {
  TrimmingOptions.missingData: 'Maximal missing data per site',
  TrimmingOptions.parsimonyInf: 'Parsimony informative sites',
};

/// Whether [value] is a valid parameter for the trimming [option].
bool isValidTrimmingValue(TrimmingOptions option, String value) {
  switch (option) {
    case TrimmingOptions.missingData:
      return isValidProportion(value);
    case TrimmingOptions.parsimonyInf:
      return isValidCount(value);
  }
}

class AlignmentTrimmingRunner {
  const AlignmentTrimmingRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFormat,
    required this.isInterleave,
    required this.option,
    required this.paramValue,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFormat;
  final bool isInterleave;
  final TrimmingOptions option;
  final String paramValue;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    await AlignmentTrimmingServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt(outputFormat, isInterleave),
      params: _matchParams(),
    ).trim();
  }

  TrimmingParams _matchParams() {
    switch (option) {
      case TrimmingOptions.missingData:
        return TrimmingParams.missingData(double.parse(paramValue));
      case TrimmingOptions.parsimonyInf:
        return TrimmingParams.parsInf(BigInt.parse(paramValue.trim()));
    }
  }
}

class UnalignmentRunner {
  const UnalignmentRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.isInterleave,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final bool isInterleave;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    await UnalignmentServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt('FASTA', isInterleave),
    ).unalign();
  }
}
