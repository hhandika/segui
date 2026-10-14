import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/output.dart';
import 'package:segui/services/io/summary.dart';

final fileInputProvider =
    AsyncNotifierProvider<FileInput, List<SegulInputFile>>(FileInput.new);

class FileInput extends AsyncNotifier<List<SegulInputFile>> {
  @override
  FutureOr<List<SegulInputFile>> build() {
    return [];
  }

  Future<void> addFiles(List<XFile> inputFiles, XTypeGroup xTypeGroup) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (inputFiles.isEmpty) {
        return [];
      }
      final files = inputFiles.map((file) {
        return SegulInputFile.fromXFile(file, xTypeGroup);
      }).toList();
      return files;
    });
  }

  Future<void> addMoreFiles(
      List<XFile> inputFiles, XTypeGroup xTypeGroup) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!];
      files.addAll(inputFiles.map(
        (file) => SegulInputFile.fromXFile(file, xTypeGroup),
      ));
      return files;
    });
  }

  Future<void> removeFromList(SegulInputFile file) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return [];
      }
      final files = [...state.value!];
      files.remove(file);
      return files;
    });
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [];
    });
  }
}

/// File list shown in the tool page's file panel.
enum FilePanelView { summary, input, output }

final filePanelViewProvider =
    NotifierProvider<FilePanelViewSelection, FilePanelView>(
        FilePanelViewSelection.new);

/// Shows the summary by default and whenever the input files change, and
/// the output files after a run.
class FilePanelViewSelection extends Notifier<FilePanelView> {
  @override
  FilePanelView build() {
    // Watching rebuilds this notifier, which is safe while widgets build.
    // Setting state from a listener throws when an invalidated input
    // provider rebuilds during a widget's build.
    ref.watch(fileInputProvider);
    return FilePanelView.summary;
  }

  void show(FilePanelView view) {
    state = view;
  }
}

/// Count, size, and formats of the selected input files.
final inputSummaryProvider = FutureProvider<FileSetSummary>((ref) async {
  final List<SegulInputFile> files = await ref.watch(fileInputProvider.future);
  return FileSetSummary.fromFiles(files.map((input) => input.file).toList());
});

/// Count, size, and formats of the new files in the output directory.
final outputSummaryProvider = FutureProvider<OutputSummary>((ref) async {
  final SegulOutputFile output = await ref.watch(fileOutputProvider.future);
  final List<File> newFiles = [
    for (final file in output.files)
      if (file.isNew) file.file,
  ];
  return OutputSummary(
    directory: output.directory,
    newFiles: await FileSetSummary.fromFiles(newFiles),
    otherFileCount: output.files.length - newFiles.length,
  );
});

/// The output directory.
/// This is use to store the output files.
final fileOutputProvider =
    AsyncNotifierProvider<FileOutput, SegulOutputFile>(FileOutput.new);

class FileOutput extends AsyncNotifier<SegulOutputFile> {
  @override
  FutureOr<SegulOutputFile> build() {
    return SegulOutputFile.empty();
  }

  /// Add the files in the output directory.
  /// This is use after the use selects the output directory.
  Future<void> add(Directory? outputDir, {bool isRecursive = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (outputDir == null) {
        return SegulOutputFile.empty();
      }
      return SegulOutputFile.fromDirectory(outputDir, isRecursive: isRecursive);
    });
  }

  /// Add files for mobile iOS and Android.
  /// Android and iOS does not allow to write
  /// files outside the app directory.
  /// So we save the files in the app directory
  Future<void> addMobile(
    String? dirName,
    SupportedTask task,
  ) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      Directory dir = await getOutputDir(dirName, task);
      return SegulOutputFile.fromDirectory(dir, isRecursive: false);
    });
  }

  Future<void> addFromAppDir() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      Directory dir = await getSeguiDirectory();
      return SegulOutputFile.fromDirectory(dir, isRecursive: true);
    });
  }

  /// Update the files in the output directory.
  /// This is use after the use executes a task.
  /// We can also do stream with `FileEntity().watch`
  /// to update the file list.
  /// But it may slow down the task execution.
  Future<void> refresh({bool isRecursive = false}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null || state.value!.directory == null) {
        return SegulOutputFile.empty();
      }
      final updates =
          SegulOutputFile.updateFiles(state.value!, isRecursive: isRecursive);
      return updates;
    });
    // A refresh follows a finished run, so show its output files.
    if (state.value?.directory != null) {
      ref.read(filePanelViewProvider.notifier).show(FilePanelView.output);
    }
  }

  Future<void> removeFile(File file) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return SegulOutputFile.empty();
      }
      final files = [...state.value!.files];
      files.removeWhere((f) => f.file.path == file.path);
      file.delete();
      return SegulOutputFile.deleteFile(state.value!, file);
    });
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null) {
        return SegulOutputFile.empty();
      }
      final files = state.value!.files.map((f) => f.file).toList();
      final log = await FileCleaningService().removeAllFiles(files);
      if (log != null) {
        return SegulOutputFile.refresh(state.value!, [log]);
      }
      return SegulOutputFile.empty();
    });
  }
}
