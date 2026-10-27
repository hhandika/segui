import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/tasks/alignment.dart';
import 'package:segui/services/types.dart';
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
    await IDExtractionServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      isMap: isMap,
      prefix: _prefix,
    ).extractId();
  }

  String? get _prefix {
    return prefix.isEmpty ? null : prefix;
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
    this.isAutoFrame = false,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFmt;
  final int tableIndex;
  final String readingFrame;

  /// Detect the reading frame of each file instead of using [readingFrame].
  final bool isAutoFrame;

  Future<void> run() async {
    String table = translationTableMap[tableIndex]!;
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    final services = TranslationServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: outputFmt,
      table: table,
      readingFrame: BigInt.parse(readingFrame),
    );
    if (isAutoFrame) {
      await services.translateSequenceAutoFrame();
    } else {
      await services.translateSequence();
    }
  }
}

enum ExtractionOptions { regex, file, id }

const Map<ExtractionOptions, String> extractionOptionsMap = {
  ExtractionOptions.id: 'Input sequence ID',
  ExtractionOptions.file: 'Input file',
  ExtractionOptions.regex: 'Write regular expression',
};

class SequenceExtractionRunner {
  const SequenceExtractionRunner(
    this.ref, {
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.params,
    required this.outputFmt,
    required this.paramsText,
  });

  final WidgetRef ref;
  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFmt;
  final ExtractionOptions params;
  final String paramsText;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);

    await SequenceExtraction(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: outputFmt,
      params: await _matchParameters(),
    ).extract();
  }

  Future<SequenceExtractionParams> _matchParameters() async {
    switch (params) {
      case ExtractionOptions.regex:
        return SequenceExtractionParams.regex(paramsText);
      case ExtractionOptions.file:
        return SequenceExtractionParams.file(await inputFileIds ?? '');
      case ExtractionOptions.id:
        List<String> ids = parseInputIds();
        return SequenceExtractionParams.id(ids);
    }
  }

  List<String> parseInputIds() {
    return paramsText.split(';');
  }

  Future<String?> get inputFileIds async {
    return await ref.read(fileInputProvider).when(
          data: (value) {
            final inputId =
                value.where((element) => element.type == SegulType.plainText);
            if (value.isEmpty || inputId.isEmpty) {
              return throw Exception(
                'No input files selected.',
              );
            } else if (inputId.length > 1) {
              return throw Exception(
                'More than one input file for parameters selected.',
              );
            } else {
              return inputId.first.file.path;
            }
          },
          loading: () => null,
          error: (e, _) => throw Exception(e.toString()),
        );
  }
}

enum RemovalOptions { id, regex }

const Map<RemovalOptions, String> removalOptionsMap = {
  RemovalOptions.id: 'Input semicolon-separated IDs',
  RemovalOptions.regex: 'Write regular expression',
};

class SequenceRemovalRunner {
  const SequenceRemovalRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.params,
    required this.paramsText,
  });

  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFmt;
  final RemovalOptions params;
  final String paramsText;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);

    await SequenceRemoval(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: outputFmt,
      removeRegex: regexValue,
      removeList: ids,
    ).removeSequence();
  }

  String? get regexValue {
    if (params == RemovalOptions.regex) {
      return paramsText;
    } else {
      return null;
    }
  }

  List<String>? get ids {
    if (params == RemovalOptions.id) {
      return paramsText.split(';');
    } else {
      return null;
    }
  }
}

enum RenamingOptions {
  renameFile,
  removeString,
  removeRegex,
  replaceString,
  replaceRegex,
}

const Map<RenamingOptions, String> renamingOptionsMap = {
  RenamingOptions.renameFile: 'Input file',
  RenamingOptions.removeString: 'Remove text',
  RenamingOptions.removeRegex: 'Remove regex',
  RenamingOptions.replaceString: 'Find and replace string',
  RenamingOptions.replaceRegex: 'Find and replace regex',
};

class SequenceRenamingRunner {
  const SequenceRenamingRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.outputDir,
    required this.outputFmt,
    required this.params,
    // Parameter values.
    // Use for original text if replacing string.
    required this.value,
    required this.replaceWithValue,
    required this.isRegexMatchAll,
  });
  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final Directory outputDir;
  final String outputFmt;
  final RenamingOptions params;
  final String? value;
  final String? replaceWithValue;
  final bool isRegexMatchAll;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);

    await SequenceRenaming(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: outputFmt,
      params: _matchParameters(),
    ).renameSequence();
  }

  SequenceRenamingParams _matchParameters() {
    switch (params) {
      case RenamingOptions.renameFile:
        return SequenceRenamingParams.renameId(value!);
      case RenamingOptions.removeString:
        return SequenceRenamingParams.removeStr(value!);
      case RenamingOptions.removeRegex:
        return SequenceRenamingParams.removeRegex(value!, isRegexMatchAll);
      case RenamingOptions.replaceString:
        return SequenceRenamingParams.replaceStr(
          value!,
          replaceWithValue!,
        );
      case RenamingOptions.replaceRegex:
        return SequenceRenamingParams.replaceRegex(
          value!,
          replaceWithValue!,
          isRegexMatchAll,
        );
    }
  }
}

class SequenceAdditionRunner {
  const SequenceAdditionRunner({
    required this.inputFiles,
    required this.inputFmt,
    required this.datatype,
    required this.destinationFmt,
    required this.outputDir,
    required this.isInterleave,
    required this.isAddedOnly,
    required this.isSingleDestination,
    required this.isFilenameIncluded,
  });

  /// Source sequences and destination files, told apart by [SegulType].
  final List<SegulInputFile> inputFiles;
  final String inputFmt;
  final String datatype;
  final String destinationFmt;
  final Directory outputDir;
  final bool isInterleave;

  /// Only write destination files that receive new sequences.
  final bool isAddedOnly;

  /// Add every sequence to one destination file.
  final bool isSingleDestination;

  /// Add the source file name to each sequence ID.
  /// Only used with [isSingleDestination].
  final bool isFilenameIncluded;

  Future<void> run() async {
    final io = IOServices();
    List<String> sources =
        io.convertPathsToString(inputFiles, SegulType.standardSequence);
    List<String> destinations =
        io.convertPathsToString(inputFiles, SegulType.destinationSequence);
    if (sources.isEmpty) {
      throw 'No input files';
    }
    if (destinations.isEmpty) {
      throw 'No destination files';
    }
    if (isSingleDestination && destinations.length > 1) {
      throw 'Select only one destination file.';
    }
    final services = SequenceAdditionServices(
      inputFiles: sources,
      inputFmt: inputFmt,
      datatype: datatype,
      destinationFiles: destinations,
      destinationFmt: destinationFmt,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt('FASTA', isInterleave),
      isAddedOnly: isAddedOnly,
    );
    if (isSingleDestination) {
      await services.addSequenceToSingleFile(
        includeFilename: isFilenameIncluded,
      );
    } else {
      await services.addSequence();
    }
  }
}

enum SequenceFilteringOptions { minimalLength, maximalLength, maximalGap }

const Map<SequenceFilteringOptions, String> sequenceFilteringOptions = {
  SequenceFilteringOptions.minimalLength: 'Minimal sequence length',
  SequenceFilteringOptions.maximalLength: 'Maximal sequence length',
  SequenceFilteringOptions.maximalGap: 'Maximal proportion of gaps',
};

/// Whether [value] is a valid parameter for the sequence filtering [option].
bool isValidSequenceFilteringValue(
    SequenceFilteringOptions option, String value) {
  switch (option) {
    case SequenceFilteringOptions.minimalLength:
    case SequenceFilteringOptions.maximalLength:
      return isValidCount(value);
    case SequenceFilteringOptions.maximalGap:
      return isValidProportion(value);
  }
}

class SequenceFilteringRunner {
  const SequenceFilteringRunner({
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
  final SequenceFilteringOptions option;
  final String paramValue;

  Future<void> run() async {
    List<String> finalInputFiles = IOServices()
        .convertPathsToString(inputFiles, SegulType.standardSequence);
    if (finalInputFiles.isEmpty) {
      throw 'No input files';
    }
    await SequenceFilteringServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt(outputFormat, isInterleave),
      params: _matchParams(),
    ).filterSequence();
  }

  SequenceFilteringParams _matchParams() {
    switch (option) {
      case SequenceFilteringOptions.minimalLength:
        return SequenceFilteringParams.minLength(
            BigInt.parse(paramValue.trim()));
      case SequenceFilteringOptions.maximalLength:
        return SequenceFilteringParams.maxLength(
            BigInt.parse(paramValue.trim()));
      case SequenceFilteringOptions.maximalGap:
        return SequenceFilteringParams.maxGap(double.parse(paramValue));
    }
  }
}

class SequenceTranspositionRunner {
  const SequenceTranspositionRunner({
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
    await SequenceTransposeServices(
      inputFiles: finalInputFiles,
      inputFmt: inputFmt,
      datatype: datatype,
      outputDir: outputDir.path,
      outputFmt: getOutputFmt('FASTA', isInterleave),
    ).transpose();
  }
}
