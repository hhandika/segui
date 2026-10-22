import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/providers/io.dart';
import 'package:segui/services/viewers/alignment.dart';
import 'package:segui/services/viewers/inspector.dart';
import 'package:segui/services/workbench.dart';

/// File set the workbench inspector lists.
enum InspectorSource {
  input('Input'),
  output('Output');

  const InspectorSource(this.label);

  final String label;
}

final inspectorSourceProvider =
    NotifierProvider<InspectorSourceSelection, InspectorSource>(
        InspectorSourceSelection.new);

/// Lists the input files until a run, then its output files.
class InspectorSourceSelection extends Notifier<InspectorSource> {
  @override
  InspectorSource build() {
    return ref.watch(lastRunProvider) == null
        ? InspectorSource.input
        : InspectorSource.output;
  }

  void show(InspectorSource source) {
    state = source;
  }
}

/// Files the inspector can pick from: the input files or the new output
/// files.
final inspectorFilesProvider =
    Provider.family<List<File>, InspectorSource>((ref, source) {
  switch (source) {
    case InspectorSource.input:
      final List<SegulInputFile> inputs =
          ref.watch(fileInputProvider).value ?? const [];
      return [for (final input in inputs) input.file];
    case InspectorSource.output:
      final SegulOutputFile? output = ref.watch(fileOutputProvider).value;
      return [
        for (final file in output?.files ?? const [])
          if (file.isNew) file.file,
      ];
  }
});

final inspectedFileProvider =
    NotifierProvider<InspectedFile, File?>(InspectedFile.new);

/// File picked in the inspector. Clears when its list changes.
class InspectedFile extends Notifier<File?> {
  @override
  File? build() {
    ref.watch(inspectorFilesProvider(ref.watch(inspectorSourceProvider)));
    return null;
  }

  void select(File? file) {
    state = file;
  }
}

/// Loads alignments for the inspector's counts: in Rust, unless overridden.
final alignmentLoaderProvider =
    Provider<AlignmentLoader>((ref) => loadAlignmentView);

/// Kind, size, and content counts of the file at a path.
final fileInspectionProvider =
    FutureProvider.autoDispose.family<FileInspection, String>((ref, path) {
  final FileInspector inspector =
      FileInspector(loadAlignment: ref.watch(alignmentLoaderProvider));
  return inspector.inspect(File(path));
});
