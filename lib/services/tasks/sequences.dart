import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/providers/io.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
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
      outputFname: _prefix,
    );
  }

  String get _prefix {
    return prefix.isNotEmpty ? prefix : 'id';
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
