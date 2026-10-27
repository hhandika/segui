import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:segui/services/io/input.dart';
import 'package:segui/services/io/input_cache.dart';
import 'package:segui/services/io/io.dart';
import 'package:segui/services/io/mobile_io.dart';
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
    _pruneCache();
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
    _pruneCache();
  }

  /// Replace the files of [xTypeGroup]'s type, keeping files of other types.
  Future<void> replaceType(
      List<XFile> inputFiles, XTypeGroup xTypeGroup) async {
    final SegulType type = matchTypeByXTypeGroup(xTypeGroup);
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final files = [...?state.value]..removeWhere((e) => e.type == type);
      files.addAll(inputFiles.map(
        (file) => SegulInputFile.fromXFile(file, xTypeGroup),
      ));
      return files;
    });
    _pruneCache();
  }

  /// Remove the files of [type], keeping files of other types.
  Future<void> removeType(SegulType type) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [...?state.value]..removeWhere((e) => e.type == type);
    });
    _pruneCache();
  }

  /// Remove the files at [paths] from the list. The files stay on disk.
  Future<void> removeFiles(Set<String> paths) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [...?state.value]..removeWhere((e) => paths.contains(e.file.path));
    });
    _pruneCache();
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
    _pruneCache();
  }

  Future<void> clearAll() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return [];
    });
    _pruneCache();
  }

  /// Deletes cached copies of files that are no longer inputs. When no
  /// inputs are left, also ends access to folders picked on iOS.
  void _pruneCache() {
    if (state.hasError) {
      return;
    }
    final Set<String> keep = {
      for (final input in state.value ?? const <SegulInputFile>[])
        input.file.path,
    };
    unawaited(_pruneCacheKeeping(keep));
  }

  Future<void> _pruneCacheKeeping(Set<String> keep) async {
    try {
      final cache = await InputCacheServices.create();
      await cache.prune(keep);
      if (keep.isEmpty && Platform.isIOS) {
        await MobileIoChannel.instance.releaseFolders();
      }
    } catch (_) {
      // Cleanup is best effort and must never fail an input change, even
      // without platform paths, as in tests. The next change retries it.
    }
  }
}

/// File list shown in the tool page's file panel.
enum FilePanelView { workbench, input, output }

final filePanelViewProvider =
    NotifierProvider<FilePanelViewSelection, FilePanelView>(
        FilePanelViewSelection.new);

/// Shows the workbench by default, whenever the input files change, and
/// after a run, where it suggests the next steps.
class FilePanelViewSelection extends Notifier<FilePanelView> {
  @override
  FilePanelView build() {
    // Watching rebuilds this notifier, which is safe while widgets build.
    // Setting state from a listener throws when an invalidated input
    // provider rebuilds during a widget's build.
    ref.watch(fileInputProvider);
    return FilePanelView.workbench;
  }

  void show(FilePanelView view) {
    state = view;
  }
}

/// The number of files shared to SEGUI from other apps that no tool has
/// taken yet.
final sharedInputProvider = NotifierProvider<SharedInput, int>(SharedInput.new);

class SharedInput extends Notifier<int> {
  @override
  int build() {
    if (!MobileIoChannel.isSupported) {
      return 0;
    }
    final channel = MobileIoChannel.instance;
    final subscription = channel.onShared.listen((count) => state = count);
    ref.onDispose(subscription.cancel);
    unawaited(_loadPending(channel));
    return 0;
  }

  /// Marks the shared files as taken by a tool.
  void clear() {
    state = 0;
  }

  Future<void> _loadPending(MobileIoChannel channel) async {
    try {
      final int count = await channel.pendingSharedCount();
      if (ref.mounted) {
        state = count;
      }
    } on Exception {
      // No shared files when the native channel is unavailable.
    }
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

  /// Treat only files written from now on as new outputs.
  /// This is used before each run, so a rerun does not count
  /// the previous run's files as its own.
  void markRunStart() {
    final SegulOutputFile? current = state.value;
    if (current == null || current.directory == null) {
      return;
    }
    state = AsyncValue.data(SegulOutputFile(
      directory: current.directory,
      files: [for (final f in current.files) (file: f.file, isNew: false)],
      // Some filesystems store modification times in whole seconds.
      selectedAt: DateTime.now().subtract(const Duration(seconds: 1)),
    ));
  }

  /// Update the files in the output directory.
  /// This is use after the use executes a task.
  /// We can also do stream with `FileEntity().watch`
  /// to update the file list.
  /// But it may slow down the task execution.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      if (state.value == null || state.value!.directory == null) {
        return SegulOutputFile.empty();
      }
      final updates = SegulOutputFile.updateFiles(state.value!);
      return updates;
    });
    // A refresh follows a finished run, so show its next steps.
    if (state.value?.directory != null) {
      ref.read(filePanelViewProvider.notifier).show(FilePanelView.workbench);
    }
  }

  /// Delete [files] from disk and from the output list.
  Future<void> deleteFiles(List<File> files) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final SegulOutputFile? current = state.value;
      if (current == null) {
        return SegulOutputFile.empty();
      }
      for (final File file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      final Set<String> paths = files.map((e) => e.path).toSet();
      return SegulOutputFile(
        directory: current.directory,
        files:
            current.files.where((e) => !paths.contains(e.file.path)).toList(),
        selectedAt: current.selectedAt,
      );
    });
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
