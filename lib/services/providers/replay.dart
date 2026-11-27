import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/controllers.dart';
import 'package:segui/services/home_features.dart';
import 'package:segui/services/io/file.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/types.dart';
import 'package:segui/src/rust/api/report.dart';

/// Resolved report inputs and parameters queued to pre-fill a SEGUI tool form.
class PendingReplay {
  const PendingReplay({
    required this.taskKind,
    required this.reportPath,
    required this.inputFiles,
    required this.auxiliaryInputs,
    required this.outputDir,
    required this.prefix,
    required this.parameters,
  });

  final String taskKind;
  final String reportPath;
  final List<String> inputFiles;
  final Map<String, List<String>> auxiliaryInputs;
  final String outputDir;
  final String? prefix;
  final Map<String, dynamic> parameters;

  String? stringParam(String key) {
    final Object? value = parameters[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  bool? boolParam(String key) {
    final Object? value = parameters[key];
    return value is bool ? value : null;
  }

  int? intParam(String key) {
    final Object? value = parameters[key];
    return value is num ? value.toInt() : null;
  }

  double? doubleParam(String key) {
    final Object? value = parameters[key];
    return value is num ? value.toDouble() : null;
  }

  /// Matches parameter [key] case-insensitively against [options].
  String? matchOption(String key, List<String> options) {
    final String? raw = stringParam(key);
    if (raw == null) {
      return null;
    }
    final String lower = raw.toLowerCase();
    for (final option in options) {
      if (option.toLowerCase() == lower) {
        return option;
      }
    }
    return null;
  }

  /// Populates common [IOController] fields from recorded parameters.
  void applyIoDefaults(
    IOController ctr, {
    List<String> inputFormats = inputFormat,
    List<String> dataTypes = dataType,
    List<String>? outputFormats,
  }) {
    if (prefix != null) {
      ctr.prefixController.text = prefix!;
    }
    if (runningPlatform == PlatformType.isMobile && outputDir.isNotEmpty) {
      ctr.outputDir.text = outputDir;
    }
    final String? matchedInput = matchOption('input_format', inputFormats);
    if (matchedInput != null) {
      ctr.inputFormatController = matchedInput;
    }
    final String? matchedDatatype = matchOption('datatype', dataTypes);
    if (matchedDatatype != null) {
      ctr.dataTypeController = matchedDatatype;
    }
    if (outputFormats != null) {
      final String? rawOut = stringParam('output_format');
      final String baseOut =
          rawOut != null && rawOut.toLowerCase().endsWith('-int')
              ? rawOut.substring(0, rawOut.length - 4)
              : (rawOut ?? '');
      for (final option in outputFormats) {
        if (option.toLowerCase() == baseOut.toLowerCase()) {
          ctr.outputFormatController = option;
          break;
        }
      }
    }
  }
}

final pendingReplayProvider =
    NotifierProvider<PendingReplayNotifier, PendingReplay?>(
  PendingReplayNotifier.new,
);

/// Holds a single-shot replay payload until the target tool form consumes it.
class PendingReplayNotifier extends Notifier<PendingReplay?> {
  @override
  PendingReplay? build() => null;

  void setReplay(PendingReplay replay) {
    state = replay;
  }

  PendingReplay? consumeFor(String taskKind) {
    final PendingReplay? current = state;
    if (current == null || current.taskKind != taskKind) {
      return null;
    }
    state = null;
    return current;
  }

  void clear() {
    state = null;
  }
}

/// Maps a canonical `segul_core::report::spec::TaskKind` wire name to its [HomeTool].
HomeTool? toolForTaskKind(String taskKind) {
  switch (taskKind) {
    case 'align.summary':
      return alignmentSummaryTool;
    case 'align.distance':
      return distanceTool;
    case 'align.concat':
      return concatenationTool;
    case 'align.convert':
      return conversionTool;
    case 'align.filter':
      return filterTool;
    case 'align.split':
      return splitTool;
    case 'align.trim':
      return trimmingTool;
    case 'align.unalign':
      return unalignmentTool;
    case 'partition.convert':
      return partitionTool;
    case 'contig.summary':
      return contigSummaryTool;
    case 'read.summary':
      return readSummaryTool;
    case 'maf.summary':
      return mafSummaryTool;
    case 'maf.convert':
      return mafConversionTool;
    case 'sequence.add':
      return additionTool;
    case 'sequence.extract':
      return extractionTool;
    case 'sequence.filter':
      return sequenceFilteringTool;
    case 'sequence.id':
      return idExtractionTool;
    case 'sequence.remove':
      return removalTool;
    case 'sequence.rename':
      return renamingTool;
    case 'sequence.translate':
      return translationTool;
    case 'sequence.transpose':
      return transpositionTool;
    default:
      return null;
  }
}

XTypeGroup _primaryTypeGroupFor(String taskKind) {
  switch (taskKind) {
    case 'read.summary':
      return genomicRawReadTypeGroup;
    case 'contig.summary':
      return genomicContigTypeGroup;
    case 'maf.summary':
    case 'maf.convert':
      return mafTypeGroup;
    case 'partition.convert':
      return partitionTypeGroup;
    default:
      return sequenceTypeGroup;
  }
}

Map<String, dynamic> _decodeParameters(String jsonText) {
  if (jsonText.trim().isEmpty) {
    return const <String, dynamic>{};
  }
  final Object? decoded = jsonDecode(jsonText);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  if (decoded is Map) {
    return decoded.map((k, v) => MapEntry(k.toString(), v));
  }
  return const <String, dynamic>{};
}

/// Loads a `report.json` replay spec into the active tool, inputs, and pending form state.
///
/// Returns an error message when the task is unsupported or none of its input files exist.
Future<String?> loadReportIntoTool(WidgetRef ref, String reportPath) async {
  final ReplaySpecDto spec = await RunReportServices.loadReplaySpec(
    reportPath: reportPath,
  );
  final HomeTool? tool = toolForTaskKind(spec.kind);
  if (tool == null) {
    return 'Unsupported task kind: ${spec.kind}';
  }

  final List<String> existingInputs = [
    for (final path in spec.primaryPaths)
      if (File(path).existsSync()) path,
  ];
  final Map<String, List<String>> auxByRole = <String, List<String>>{};
  for (int i = 0; i < spec.auxiliaryRoles.length; i++) {
    if (i >= spec.auxiliaryPaths.length) {
      break;
    }
    final String role = spec.auxiliaryRoles[i];
    final String path = spec.auxiliaryPaths[i];
    if (File(path).existsSync()) {
      auxByRole.putIfAbsent(role, () => <String>[]).add(path);
    }
  }

  final Map<String, dynamic> parameters =
      _decodeParameters(spec.parametersJson);
  final Object? rawPrefix = parameters['prefix'];
  final String? prefix =
      rawPrefix is String && rawPrefix.isNotEmpty ? rawPrefix : null;

  await ref.read(fileInputProvider.notifier).clearAll();
  if (existingInputs.isNotEmpty) {
    await ref.read(fileInputProvider.notifier).addFiles(
      [for (final path in existingInputs) XFile(path)],
      _primaryTypeGroupFor(spec.kind),
    );
  }
  if (spec.kind == 'maf.convert') {
    final List<String> bedFiles = auxByRole['bed'] ?? const <String>[];
    if (bedFiles.isNotEmpty) {
      await ref.read(fileInputProvider.notifier).addMoreFiles(
        [for (final path in bedFiles) XFile(path)],
        bedTypeGroup,
      );
    }
  }
  if (spec.kind == 'align.distance') {
    final List<String> groupFiles = auxByRole['groups'] ?? const <String>[];
    if (groupFiles.isNotEmpty) {
      await ref.read(fileInputProvider.notifier).addMoreFiles(
        [for (final path in groupFiles) XFile(path)],
        sampleGroupTypeGroup,
      );
    }
  }
  if (spec.outputDir.isNotEmpty) {
    final Directory outDir = Directory(spec.outputDir);
    if (outDir.existsSync()) {
      await ref.read(fileOutputProvider.notifier).add(outDir);
    }
  }

  ref.read(pendingReplayProvider.notifier).setReplay(
        PendingReplay(
          taskKind: spec.kind,
          reportPath: reportPath,
          inputFiles: existingInputs,
          auxiliaryInputs: auxByRole,
          outputDir: spec.outputDir,
          prefix: prefix,
          parameters: parameters,
        ),
      );
  ref.read(homeToolNavigatorProvider).open(tool);

  if (existingInputs.isEmpty && spec.primaryPaths.isNotEmpty) {
    return 'Original input files were not found on disk; re-select inputs in the tool.';
  }
  return null;
}

/// Prompts the user for a destination and writes [contents] as UTF-8 text.
///
/// Returns the saved path, or `null` if cancelled.
Future<String?> saveGeneratedTextFile({
  required String suggestedName,
  required String contents,
  List<String> extensions = const <String>['txt'],
  String label = 'Text file',
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final Uri? uri = await FilePicker.saveFile(
      fileName: suggestedName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
    );
    if (uri == null) {
      return null;
    }
    return uri.scheme == 'file' ? uri.toFilePath() : suggestedName;
  }
  final FileSaveLocation? location = await getSaveLocation(
    suggestedName: suggestedName,
    acceptedTypeGroups: [
      XTypeGroup(label: label, extensions: extensions),
    ],
  );
  if (location == null) {
    return null;
  }
  await File(location.path).writeAsString(contents);
  return location.path;
}
